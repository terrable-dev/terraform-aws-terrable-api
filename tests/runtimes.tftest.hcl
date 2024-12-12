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