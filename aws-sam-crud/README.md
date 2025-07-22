# AWS SAM CRUD API - Copilot Instructions

This project is an AWS SAM CRUD API using API Gateway, Lambda, and DynamoDB with Python. It follows AWS best practices for serverless CRUD APIs.

## Next Steps

1. Update the `template.yaml` to define Lambda functions for Create, Read, Update, and Delete operations, and add a DynamoDB table resource.
2. Implement the Lambda function handlers in Python to perform CRUD operations on DynamoDB.
3. Update the API Gateway event definitions to map HTTP methods and paths to the correct Lambda functions.
4. Deploy the stack using `sam deploy --guided`.

## Useful Commands
- Build: `sam build`
- Local test: `sam local invoke` or `sam local start-api`
- Deploy: `sam deploy --guided`

---

For more details, see the AWS SAM documentation: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html
