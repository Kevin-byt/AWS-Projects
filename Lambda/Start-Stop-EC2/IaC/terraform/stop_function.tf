# Archive stop.py for Lambda function  
data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = "./stop.py"
  output_path = "./stop.zip"  
}

resource "aws_lambda_function" "stop_instances" {
  filename      = "./stop.zip"
  function_name = "stop-instances"
  role          = aws_iam_role.lambda_role.arn
  handler       = "stop.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      INSTANCE_TAG = "env=test"
    }
  }
}