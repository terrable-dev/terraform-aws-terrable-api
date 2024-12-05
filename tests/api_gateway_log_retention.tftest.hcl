mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name           = "test-api"
  log_retention_days = 3
  handlers = {
    TestHandler : {
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
    }
  }
}

run "cloudwatch_log_groups_created_with_set_retention_days" {
  assert {
    condition = alltrue([
      for key, handler in var.handlers :
      aws_cloudwatch_log_group.lambda_log_groups[key].retention_in_days == 3
    ])

    error_message = "configured retention days not set correctly"
  }
}
