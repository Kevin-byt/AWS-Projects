# Serverless Architecture on AWS: A Guide

**Introduction:**
Welcome to the guide on setting up a serverless architecture on AWS. This README provides an overview of the steps outlined in the blog titled [Serverless Architecture on AWS](https://kevinkiruri.medium.com/serverless-architecture-on-aws-be3d6bd13f9a) by [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/).

## Steps
1. **Creating an S3 Bucket**: Set up an S3 bucket to store data files.
2. **Creating a DynamoDB Table**: Establish a DynamoDB table to store inventory data.
3. **Creating an SNS Topic**: Create an SNS topic for sending notifications.
4. **Creating Roles for Lambda Functions**: Set up IAM roles for Lambda functions to access S3, DynamoDB, and SNS.
5. **Creating Lambda Functions**: Develop Lambda functions to read from S3, update DynamoDB, and send SNS notifications.

## Testing

1. **Upload a CSV File**: Upload a CSV file with store, product, and count columns to the S3 bucket.
2. **Verify Functionality**: Ensure Lambda functions process the file, update DynamoDB, and send notifications for low inventory.

## Clean Up

1. **Delete Resources**: Remove uploaded objects, S3 bucket, SNS topic, DynamoDB table, Lambda functions, and associated IAM roles.

## Using CloudFormation
You can create a CloudFormation template to create the above infrasture in the click of a button.

## Conclusion

Implementing serverless architecture on AWS enables efficient handling of various business use cases, such as inventory management. By leveraging AWS services like S3, DynamoDB, SNS, and Lambda, you can automate processes and streamline workflows. Serverless architecture empowers systems to respond dynamically to events, enhancing agility and scalability in cloud environments.

---

*Author: [Kevin Kiruri](https://www.linkedin.com/in/kevin-kiruri/)*