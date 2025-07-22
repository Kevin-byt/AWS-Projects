import json
from aws_lambda_powertools import Logger, Tracer
import boto3
import requests

# sam-crud/core/app.py
logger = Logger()
tracer = Tracer()


def lambda_handler(event, context):
    """Sample pure Lambda function

    Parameters
    ----------
    event: dict, required
        API Gateway Lambda Proxy Input Format

    context: object, required
        Lambda Context runtime methods and attributes
    Returns
    ------
    API Gateway Lambda Proxy Output Format: dict
    """

    http_method = event.get('httpMethod')
    path = event.get('path')

    if http_method == 'POST':
        try:
            data = event.get('body', {})
            # check if data is dict - if its a string convert to dict
            while isinstance(data, str):
                data = json.loads(data)
            logger.info(f"Request Data (body): {data}")
            match path:
                case '/create':
                    return create(data)
                case '/read':
                    return read(data)
                case '/update':
                    return update(data)
                case '/delete':
                    return delete(data)
                case _:
                    return make_response(404, {'message': 'Path Not Found'})

        except json.JSONDecodeError as e:
            logger.error("Error decoding JSON body")
            return make_response(400, {'message': 'Invalid JSON body','error': str(e)})


        except Exception as e:
            logger.error(f"An unexpected error occurred in lambda_handler: {e}")
            return make_response(500, {'message': 'Internal Server Error', 'error': str(e)})

    else:
        logger.error('Method Not Allowed - received {http_method}')
        return make_response(405, {'message': 'Method Not Allowed','error': 'Method Not Allowed'})

def create(data):
    """
    Create a new item in the DynamoDB table.
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('crud')
        response = table.put_item(Item=data)
        return make_response(200, {'message': 'Item created successfully'})
    except Exception as e:
        logger.error(f"Error creating item: {e}")
        return make_response(500, {'message': 'Internal Server Error', 'error': str(e)})

def read(data):
    """
    Read an item from the DynamoDB table.
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('crud')
        response = table.get_item(Key={'id': data.get('id')})
        if 'Item' in response:
            return make_response(200, response['Item'])
        else:
            return make_response(404, {'message': 'Item not found'})
    except Exception as e:
        logger.error(f"Error reading item: {e}")
        return make_response(500, {'message': 'Internal Server Error', 'error': str(e)})

def update(data):
    """
    Update an existing item in the DynamoDB table.
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('crud')
        response = table.update_item(
            Key={'id': data.get('id')},
            UpdateExpression='SET #attr = :val',
            ExpressionAttributeNames={'#attr': data.get('attribute')},
            ExpressionAttributeValues={':val': data.get('value')},
            ReturnValues='UPDATED_NEW'
        )
        return make_response(200, {'message': 'Item updated successfully', 'updatedAttributes': response['Attributes']})
    except Exception as e:
        logger.error(f"Error updating item: {e}")
        return make_response(500, {'message': 'Internal Server Error', 'error': str(e)})

def delete(data):

    """
    Delete an item from the DynamoDB table.
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('crud')
        response = table.delete_item(Key={'id': data.get('id')})
        return make_response(200, {'message': 'Item deleted successfully'})
    except Exception as e:
        logger.error(f"Error deleting item: {e}")
        return make_response(500, {'message': 'Internal Server Error', 'error': str(e)})


def make_response(status_code, body):
    """
    Helper function to format responses for API Gateway.
    """
    response = {
        'statusCode': status_code,
        'body': json.dumps(body)
    }
    logger.info(f"Response: {response}")
    return response
