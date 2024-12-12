mock_provider "aws" {
  source = "./tests/mocks"
}

run "regional_endpoint_type" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      endpoint_type = "REGIONAL"
    }

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
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "REGIONAL"
    error_message = "API Gateway endpoint type configuration should be 'REGIONAL'"
  }
}

run "implicit_endpoint_type" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
    }

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
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "REGIONAL"
    error_message = "API Gateway endpoint type configuration should be 'REGIONAL'"
  }
}

run "edge_endpoint_type" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      endpoint_type = "EDGE"
    }

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
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "EDGE"
    error_message = "API Gateway endpoint type configuration should be 'EDGE'"
  }
}

run "private_endpoint_type" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      endpoint_type = "PRIVATE"
    }

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
    condition     = aws_api_gateway_rest_api.api_gateway[0].endpoint_configuration[0].types[0] == "PRIVATE"
    error_message = "API Gateway endpoint type configuration should be 'PRIVATE'"
  }
}

run "invalid_endpoint_type" {
  command = plan

  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      endpoint_type = "INVALID"
    }

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
    var.rest_api.endpoint_type
  ]
}

