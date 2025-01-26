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
        queue = "sqs:queue:arn"
      }
    }
  }
}

run "default_event_source_mapping_configuration" {
  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].batch_size == 1
    error_message = "Incorrect default batch size"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_event_source["SqsHandler"].scaling_config[0].maximum_concurrency == 2
    error_message = "Incorrect default concurrency"
  }
}
