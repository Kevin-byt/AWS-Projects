import os
import json
from datetime import datetime
import boto3

def lambda_handler(event, context):
    # Get information about the uploaded object from the S3 event
    s3_event = event['Records'][0]['s3']
    bucket_name = s3_event['bucket']['name']
    object_key = s3_event['object']['key']
    object_size = s3_event['object']['size']

    # Get the current timestamp
    upload_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Prepare message to be sent to SNS
    message = {
        'bucket_name': bucket_name,
        'object_name': object_key,
        'object_size': object_size,
        'upload_time': upload_time
    }

    # Convert the message to JSON
    message_json = json.dumps(message)

    # Set up the SNS client
    sns_client = boto3.client('sns')

    # Replace 'YOUR_SNS_TOPIC_ARN' with your actual SNS topic ARN
    sns_topic_arn = 'YOUR_SNS_TOPIC_ARN'

    # Publish the message to the SNS topic
    sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=message_json,
        Subject=f"Object Uploaded: {object_key}"
    )

    print(f"Message published to SNS: {message_json}")

    return {
        'statusCode': 200,
        'body': json.dumps('Message published to SNS successfully!')
    }
