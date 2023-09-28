# Stop the instances:

import boto3

region = 'us-east-1'
instances = ['i-0f2e6b01433dde304', 'i-0e07ca750de438b4a', 'i-00e0d28eab8a14b07', 'i-01fee43565ceeedca']
ec2 = boto3.client('ec2', region_name=region)


def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stopped your instances: ' + str(instances))
