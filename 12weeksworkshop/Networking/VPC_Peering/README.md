# VPC Peering on AWS

## Introduction

Welcome to the VPC Peering Guide for AWS. This README provides an overview of the steps detailed in [Bridging VPCs: A Practical Guide to VPC Peering in AWS](https://medium.com/@kevinkiruri/creating-a-vpc-peering-connection-on-aws-ff35156e39b9), authored by [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/).

## Prerequisites

Before establishing VPC Peering connections on AWS, make sure you have an AWS account, access to the required project files, and the necessary networking prerequisites in place.

## Steps

### Step 1: Prepare Networking Prerequisites

1. **Install essential CloudFormation templates:** Install necessary [CloudFormation template](pre-requisites.yaml) to create IAM roles and an S3 Bucket.
2. **Access the AWS Console:** Access the AWS Console and navigate to the CloudFormation service.
3. **Create a CloudFormation stack:** Create a CloudFormation stack using the provided templates.

### Step 2: Create Three VPCs

1. **Utilize a CloudFormation template:** Utilize a [CloudFormation template](create_VPC.yaml) to create VPC A, VPC B, and VPC C, each with specific configurations.
2. **Access the AWS Console:** Access the AWS Console and navigate to the CloudFormation service.
3. **Create a CloudFormation stack:** Create a CloudFormation stack using the VPC template.

### Step 3: Establish VPC Peering Connections

1. **Set up VPC peering between VPC A and VPC B:** Configure VPC peering between VPC A and VPC B.
2. **Modify route tables:** Modify route tables for VPC A and VPC B to enable traffic flow.
3. **Repeat the peering and route table setup:** Repeat the peering and route table setup for VPC A and VPC C.

### Step 4: Check Connectivity

1. **Access the EC2 Console:** Access the EC2 Console.
2. **Verify the connectivity:** Verify the connectivity by pinging instances between VPCs.

### Step 5: Clean-Up

1. **Delete VPC peering connections:** Delete VPC peering connections to ensure they are properly removed.
2. **Confirm the loss of connectivity:** Confirm the loss of connectivity after deletion.

## Conclusion

- Recognize the significance of VPC Peering for efficient AWS network connections.
- Consider the scalability challenges and the potential transition to AWS Transit Gateway for managing network connections at scale.

---

Author: [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/)
