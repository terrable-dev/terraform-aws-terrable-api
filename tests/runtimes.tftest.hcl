mock_provider "aws" {
  source = "./tests/mocks"
}

run "valid_global_runtime" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    handlers = {
      TestHandler = {
        source = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = var.runtime == "nodejs20.x"
    error_message = "Global runtime should be set to nodejs20.x"
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].runtime == "nodejs20.x"
    error_message = "Lambda function should use the global runtime"
  }
}

run "valid_handler_runtime" {
  variables {
    api_name = "test-api"
    handlers = {
      TestHandler = {
        source  = "./tests/handler.js"
        runtime = "nodejs20.x"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = var.handlers.TestHandler.runtime == "nodejs20.x"
    error_message = "Handler runtime should be set to nodejs20.x"
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].runtime == "nodejs20.x"
    error_message = "Lambda function should use the handler-specific runtime"
  }
}

run "handler_runtime_overrides_global" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs18.x"
    handlers = {
      TestHandler = {
        source  = "./tests/handler.js"
        runtime = "python3.9"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].runtime == "python3.9"
    error_message = "Lambda function should use handler-specific runtime over global runtime"
  }
}

run "no_runtime_specified" {
  command = plan

  variables {
    api_name = "test-api"
    handlers = {
      TestHandler = {
        source = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
    }
  }

  expect_failures = [
    var.handlers
  ]
}