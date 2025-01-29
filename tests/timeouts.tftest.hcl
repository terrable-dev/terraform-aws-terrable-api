mock_provider "aws" {
  source = "./tests/mocks"
}

run "with_default_global_timeout" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    handlers = {
      TestHandler : {
        source = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].timeout == 3
    error_message = "TestHandler does not have default timeout (3 seconds) set"
  }
}

run "with_explicit_global_timeout" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    timeout  = 25

    handlers = {
      TestHandler : {
        source = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].timeout == 25
    error_message = "TestHandler does not have specified timeout (25 seconds) set"
  }
}

run "with_specific_handler_timeout" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    timeout  = 25

    handlers = {
      TestHandler : {
        source = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
      OtherHandler : {
        timeout = 10
        source  = "./tests/handler.js"
        http = {
          GET = "/"
        }
      }
    }
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].timeout == 25
    error_message = "TestHandler does not have specified timeout (25 seconds) set"
  }

  assert {
    condition     = aws_lambda_function.handlers["OtherHandler"].timeout == 10
    error_message = "OtherHandler does not have specified timeout (10 seconds) set"
  }
}
