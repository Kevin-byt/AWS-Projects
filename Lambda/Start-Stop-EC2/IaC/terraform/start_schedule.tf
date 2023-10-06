resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "start-instances-schedule"
  description         = "Start test instances at 8am weekdays"
  schedule_expression = "cron(0 8 ? * MON-FRI *)" #Time in UTC
#   schedule_expression = "cron(00 14 ? * * *)" #Time in UTC
}

# Add Lambda functions as targets for CloudWatch rules
resource "aws_cloudwatch_event_target" "start_schedule_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "start_instances"
  arn       = aws_lambda_function.start_instances.arn
}

# Give CloudWatch permission to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}