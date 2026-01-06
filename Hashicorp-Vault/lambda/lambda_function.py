import boto3
import requests
import pymysql
import os
import json
import base64
import logging
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import ReadOnlyCredentials

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class VaultAuthError(Exception):
    """Custom exception for Vault authentication failures"""
    pass

class DatabaseConnectionError(Exception):
    """Custom exception for database connection failures"""
    pass

def get_vault_token():
    """
    Authenticate with Vault using AWS IAM method
    Returns: Vault token string
    """
    try:
        # Get AWS credentials from Lambda execution role
        session = boto3.Session()
        credentials = session.get_credentials()
        
        if credentials is None:
            raise VaultAuthError("No AWS credentials available")
            
        frozen_creds = credentials.get_frozen_credentials()
        
        # Prepare the STS request for signing
        request = AWSRequest(
            method="POST",
            url="https://sts.amazonaws.com/",
            headers={
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Host": "sts.amazonaws.com",
                "X-Amz-Date": boto3.Session()._session.get_credentials()._get_credentials().token
            },
            data="Action=GetCallerIdentity&Version=2011-06-15".encode('utf-8')
        )
        
        # Sign the request
        sigv4 = SigV4Auth(frozen_creds, "sts", "us-east-1")
        sigv4.add_auth(request)
        
        # Prepare the Vault login request
        iam_request = {
            "role": "lambda-role",
            "iam_http_request_method": request.method,
            "iam_request_url": base64.b64encode(request.url.encode('utf-8')).decode('utf-8'),
            "iam_request_body": base64.b64encode(request.body).decode('utf-8') if request.body else "",
            "iam_request_headers": base64.b64encode(
                json.dumps(dict(request.headers)).encode('utf-8')
            ).decode('utf-8')
        }
        
        vault_addr = os.environ['VAULT_ADDR']
        logger.info(f"Authenticating with Vault at: {vault_addr}")
        
        auth_response = requests.post(
            f"{vault_addr}/v1/auth/aws/login",
            json=iam_request,
            timeout=10
        )
        
        if auth_response.status_code != 200:
            logger.error(f"Vault authentication failed: {auth_response.status_code} - {auth_response.text}")
            raise VaultAuthError(f"Vault auth failed with status {auth_response.status_code}")
        
        response_data = auth_response.json()
        return response_data['auth']['client_token']
        
    except Exception as e:
        logger.error(f"Error during Vault authentication: {str(e)}")
        raise VaultAuthError(f"Authentication error: {str(e)}")

def get_database_credentials(vault_token):
    """
    Retrieve dynamic database credentials from Vault
    """
    try:
        vault_addr = os.environ['VAULT_ADDR']
        headers = {'X-Vault-Token': vault_token}
        
        logger.info("Requesting database credentials from Vault...")
        
        creds_response = requests.get(
            f"{vault_addr}/v1/database/creds/lambda-role",
            headers=headers,
            timeout=10
        )
        
        if creds_response.status_code != 200:
            logger.error(f"Failed to get credentials: {creds_response.status_code} - {creds_response.text}")
            raise VaultAuthError("Failed to retrieve database credentials")
        
        credentials = creds_response.json()['data']
        logger.info(f"Retrieved credentials for user: {credentials['username']}")
        
        return credentials
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Network error fetching credentials: {str(e)}")
        raise VaultAuthError(f"Credential fetch error: {str(e)}")

def create_table_if_not_exists(connection):
    """
    Create the logs table if it doesn't exist
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS logs (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    message TEXT,
                    source_ip VARCHAR(45),
                    user_agent TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            connection.commit()
            logger.info("Verified/Created logs table")
    except Exception as e:
        logger.warning(f"Could not create table: {str(e)}")

def lambda_handler(event, context):
    """
    Main Lambda handler function
    """
    try:
        logger.info("Lambda function started")
        
        # Step 1: Get Vault token using IAM authentication
        logger.info("Authenticating with Vault...")
        vault_token = get_vault_token()
        
        # Step 2: Retrieve dynamic database credentials
        logger.info("Retrieving database credentials...")
        db_creds = get_database_credentials(vault_token)
        
        # Step 3: Connect to RDS using dynamic credentials
        logger.info("Connecting to RDS...")
        connection = pymysql.connect(
            host=os.environ['RDS_ENDPOINT'],
            port=3306,
            user=db_creds['username'],
            password=db_creds['password'],
            database=os.environ['DATABASE_NAME'],
            connect_timeout=10,
            cursorclass=pymysql.cursors.DictCursor
        )
        
        # Step 4: Ensure table exists
        create_table_if_not_exists(connection)
        
        # Step 5: Execute database operation
        with connection.cursor() as cursor:
            # Extract request info from API Gateway event or use defaults
            source_ip = "unknown"
            user_agent = "unknown"
            
            if 'requestContext' in event and 'identity' in event['requestContext']:
                source_ip = event['requestContext']['identity'].get('sourceIp', 'unknown')
                user_agent = event['requestContext']['identity'].get('userAgent', 'unknown')
            
            cursor.execute("""
                INSERT INTO logs (message, source_ip, user_agent) 
                VALUES (%s, %s, %s)
            """, (
                'Lambda function executed securely with Vault dynamic credentials',
                source_ip,
                user_agent
            ))
            connection.commit()
        
        # Step 6: Query to verify insertion
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as count FROM logs")
            result = cursor.fetchone()
            log_count = result['count']
        
        connection.close()
        
        logger.info(f"Database operation completed successfully. Total log entries: {log_count}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Operation completed successfully',
                'database_user': db_creds['username'],
                'log_entries_count': log_count,
                'vault_credentials_used': True
            })
        }
        
    except VaultAuthError as e:
        logger.error(f"Vault authentication error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Vault authentication failed', 'details': str(e)})
        }
        
    except pymysql.Error as e:
        logger.error(f"Database connection error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Database connection failed', 'details': str(e)})
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error', 'details': str(e)})
        }