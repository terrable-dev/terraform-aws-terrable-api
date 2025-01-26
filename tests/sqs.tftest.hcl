mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  handlers = {
    SqsHandler = {
      source = "./tests/handler.js"
      sqs = {
        queue               = "sqs:queue:arn"
        batch_size          = 5
        maximum_concurrency = 4
      }
    }
  }
}

run "creates_event_source_mapping" {
  assert {
    condition     = length(aws_lambda_event_source_mapping.sqs_event_source) == 1
    error_message = "SQS event source mapping not created"
  }
}

run "event_source_mapping_configuration" {
  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].batch_size == 5
    error_message = "Incorrect batch size"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].scaling_config[0].maximum_concurrency == 4
    error_message = "Incorrect concurrency"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].enabled == true
    error_message = "Event source mapping not enabled"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].event_source_arn == var.handlers.SqsHandler.sqs.queue
    error_message = "Incorrect queue ARN"
  }
}

run "creates_iam_policy" {
  assert {
    condition     = length(aws_iam_role_policy.sqs_policy) == 1
    error_message = "SQS IAM policy not created"
  }
}

run "iam_policy_permissions" {
  assert {
    condition     = contains(jsondecode(aws_iam_role_policy.sqs_policy["SqsHandler"].policy).Statement[0].Action, "sqs:ReceiveMessage")
    error_message = "Missing SQS receive message permission"
  }
}
