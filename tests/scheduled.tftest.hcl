mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  handlers = {
    ScheduledHandler = {
      source = "./tests/handler.js"
      schedule = {
        expression = "cron(0 */2 * * ? *)"
      }
    }
  }
}

run "creates_cloudwatch_event_rule" {
  assert {
    condition     = length(aws_cloudwatch_event_rule.handler_scheduled) == 1
    error_message = "Cloudwatch event rule not created"
  }
}

run "event_target_configuration" {
  assert {
    condition     = aws_cloudwatch_event_target.lambda_target["ScheduledHandler"].rule == "ScheduledHandler-scheduled"
    error_message = "Incorrect rule name"
  }

  assert {
    condition     = aws_cloudwatch_event_target.lambda_target["ScheduledHandler"].arn == aws_lambda_function.handlers["ScheduledHandler"].arn
    error_message = "Incorrect arn"
  }
}

run "lambda_eventbridge_permissions" {
  assert {
    condition     = aws_lambda_permission.allow_eventbridge["ScheduledHandler"].statement_id == "AllowExecutionFromEventBridge-ScheduledHandler"
    error_message = "Incorrect statement id"
  }

  assert {
    condition     = aws_lambda_permission.allow_eventbridge["ScheduledHandler"].action == "lambda:InvokeFunction"
    error_message = "Incorrect action"
  }

  assert {
    condition     = aws_lambda_permission.allow_eventbridge["ScheduledHandler"].function_name == "test-api-ScheduledHandler"
    error_message = "Incorrect function name"
  }

  assert {
    condition     = aws_lambda_permission.allow_eventbridge["ScheduledHandler"].principal == "events.amazonaws.com"
    error_message = "Incorrect principal"
  }

  assert {
    condition     = aws_lambda_permission.allow_eventbridge["ScheduledHandler"].source_arn == "arn:aws:events:us-east-1:123456789012:rule/ScheduledHandler-scheduled"
    error_message = "Incorrect source arn"
  }
}
