import json
import boto3
import csv
import os

def lambda_handler(event, context):
    # Get the S3 bucket and object information from the event
    s3_bucket = event['Records'][0]['s3']['bucket']['name']
    s3_key = event['Records'][0]['s3']['object']['key']

    # Set the DynamoDB table name
    dynamo_table_name = 'AppleInventoryTable'

    # Create a DynamoDB client
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamo_table_name)

    # Create an S3 client
    s3 = boto3.client('s3')

    # Download the CSV file from S3
    temp_file_path = '/tmp/temp.csv'
    s3.download_file(s3_bucket, s3_key, temp_file_path)

    # Read and process the CSV file, skipping the header row
    with open(temp_file_path, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        # Skip the header row
        next(csvreader, None)
        
        for row in csvreader:
            store = row[0]
            product = row[1]
            count = int(row[2])
            

            # Update DynamoDB table
            table.put_item(
                Item={
                    'StoreRegion': store,
                    'Product': product,
                    'ProductCount': count
                }
            )
    
    # Clean up the temporary file
    os.remove(temp_file_path)

    return {
        'statusCode': 200,
        'body': 'CSV processing complete'
    }
