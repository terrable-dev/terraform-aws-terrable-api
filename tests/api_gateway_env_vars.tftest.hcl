mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  runtime  = "nodejs20.x"

  global_environment_variables = {
    GLOBAL_ONE = "global-value"
    SSM_GLOBAL = "SSM:/test/global/value"
  }
  handlers = {
    HandlerOne : {
      environment_variables = {
        LOCAL_HANDLER_ONE = "local-value"
        SSM_LOCAL         = "SSM:/test/local/value"
      }
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
    }
    HandlerTwo : {
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
    }
  }
}

run "check_HandlerOne_environment_variables" {
  assert {
    condition     = length(aws_lambda_function.handlers["HandlerOne"].environment[0].variables) == 4
    error_message = "HandlerOne has incorrect number of environment variables set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerOne"].environment[0].variables["GLOBAL_ONE"] == "global-value"
    error_message = "HandlerOne does not have correct global env variable set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerOne"].environment[0].variables["SSM_GLOBAL"] == "ssm-mocked-value"
    error_message = "HandlerOne does not have correct global env variable set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerOne"].environment[0].variables["LOCAL_HANDLER_ONE"] == "local-value"
    error_message = "HandlerOne does not have correct local env variables set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerOne"].environment[0].variables["SSM_LOCAL"] == "ssm-mocked-value"
    error_message = "HandlerOne does not have correct local env variables set"
  }
}

run "check_HandlerTwo_environment_variables" {
  assert {
    condition     = length(aws_lambda_function.handlers["HandlerTwo"].environment[0].variables) == 2
    error_message = "HandlerTwo has incorrect number of environment variables set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerTwo"].environment[0].variables["GLOBAL_ONE"] == "global-value"
    error_message = "HandlerTwo does not have correct global env variable set"
  }

  assert {
    condition     = aws_lambda_function.handlers["HandlerTwo"].environment[0].variables["SSM_GLOBAL"] == "ssm-mocked-value"
    error_message = "HandlerTwo does not have correct global env variable set"
  }
}
