import boto3
import json
import os

def lambda_handler(event, context):
    # Define DynamoDB and SNS clients
    dynamo_table_name = 'AppleInventoryTable'
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamo_table_name)
    sns = boto3.client('sns')
    region = os.environ['AWS_REGION']
    account_id = context.invoked_function_arn.split(":")[4]

    # Scan DynamoDB table to get items with count of 5 or less than 5
    response = table.scan(
        FilterExpression=boto3.dynamodb.conditions.Attr('ProductCount').lt(6)
    )
    
    # Check if there are items with count less than 5
    items = response.get('Items', [])
    
    if items:
        # Prepare notification message
        notification_message = "Low inventory alert:\n"
        for item in items:
            notification_message += f"StoreRegion: {item['StoreRegion']}, Item: {item['Product']}, Count: {item['ProductCount']}\n"

        # Publish notification to SNS
        sns.publish(
            TopicArn = f'arn:aws:sns:{region}:{account_id}:LowInventoryTopic',
            Message=notification_message,
            Subject='Low Inventory Alert'
        )
        
        return {
            'statusCode': 200,
            'body': 'Notification sent successfully.'
        }
    else:
        return {
            'statusCode': 200,
            'body': 'No items with count less than 5.'
        }
        