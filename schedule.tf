resource "aws_cloudwatch_event_rule" "handler_cron" {
  for_each = {
    for name, handler in var.handlers : name => handler.schedule
    if handler.schedule != null
  }

  name                = "${each.key}-scheduled"
  schedule_expression = each.value.cron
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = aws_cloudwatch_event_rule.handler_cron

  rule      = aws_cloudwatch_event_rule.handler_cron[each.key].name
  arn       = aws_lambda_function.handlers[each.key].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = aws_cloudwatch_event_rule.handler_cron

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handlers[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.handler_cron[each.key].arn
}
