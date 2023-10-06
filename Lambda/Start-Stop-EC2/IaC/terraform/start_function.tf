# Archive start.py for Lambda function
data "archive_file" "start_lambda_zip" {
  type        = "zip" 
  source_file = "./start.py"
  output_path = "./start.zip"
}

# Create Lambda functions to start/stop test instances
resource "aws_lambda_function" "start_instances" {
  filename      = "./start.zip"
  function_name = "start-instances"
  role          = aws_iam_role.lambda_role.arn
  handler       = "start.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      INSTANCE_TAG = "env=test" 
    }
  }
}
