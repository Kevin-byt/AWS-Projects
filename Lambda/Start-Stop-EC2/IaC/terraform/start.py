# Start the instances in the test environment:

import boto3

# AWS region and tag details
aws_region = 'us-east-1'
tag_key = 'env'
tag_value = 'test'

# Create an EC2 client
ec2 = boto3.client('ec2', region_name=aws_region)

def lambda_handler(event, context):
    # Get instances with the specified tag and value
    instances_to_start = get_instances_with_tag(tag_key, tag_value)
    
    if instances_to_start:
        # Start the instances
        start_instances(instances_to_start)
        return {
            'statusCode': 200,
            'body': 'Started instances: {}'.format(instances_to_start)
        }
    else:
        print('No instances')
        return {
            'statusCode': 200,
            'body': 'No instances found with tag "{}" and value "{}".'.format(tag_key, tag_value)
        }

def get_instances_with_tag(key, value):
    try:
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': 'tag:' + key,
                    'Values': [value]
                }
            ]
        )
        
        instances = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances.append(instance['InstanceId'])
        
        print(instances)
        return instances
        
    except Exception as e:
        print('Error:', e)
        return []

 
def start_instances(instance_ids):
    try:
        ec2.start_instances(InstanceIds=instance_ids)
        print('Starting instances:', instance_ids)
    except Exception as e:
        print('Error:', e)