resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "stop-instances-schedule" 
  description         = "Stop test instances at 5pm weekdays"
  schedule_expression = "cron(0 17 ? * MON-FRI *)"  #Time in UTC
#   schedule_expression = "cron(55 13 ? * * *)" #Time in UTC
}

resource "aws_cloudwatch_event_target" "stop_schedule_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "stop_instances"
  arn       = aws_lambda_function.stop_instances.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}
