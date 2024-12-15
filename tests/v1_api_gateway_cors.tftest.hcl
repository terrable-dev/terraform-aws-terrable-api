mock_provider "aws" {
  source = "./tests/mocks"
}

run "test_cors_configuration" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    rest_api = {
      cors = {
        allow_origins     = ["*"]
        allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
        expose_headers    = ["Content-Length", "X-My-Header"]
        max_age           = 3600
        allow_credentials = false
      }
    }

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
    condition     = aws_api_gateway_method.options["/"].http_method == "OPTIONS"
    error_message = "Root OPTIONS method not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_method.options["/"].authorization == "NONE"
    error_message = "Root OPTIONS method authorization not set to NONE"
  }

  assert {
    condition     = aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Headers"] == true
    error_message = "Root OPTIONS method response header for Access-Control-Allow-Headers not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == true
    error_message = "Root OPTIONS method response header for Access-Control-Allow-Methods not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == true
    error_message = "Root OPTIONS method response header for Access-Control-Allow-Origin not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_integration.options["/"].type == "MOCK"
    error_message = "Integration type is not MOCK"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == "'*'"
    error_message = "Root OPTIONS integration response parameter for Access-Control-Allow-Origin not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST,PUT,DELETE,OPTIONS'"
    error_message = "Root OPTIONS integration response parameter for Access-Control-Allow-Methods not configured correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'3600'"
    error_message = "Root OPTIONS integration response parameter for Access-Control-Max-Age not configured correctly"
  }
}

run "test_cors_disabled" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    rest_api = {
    }

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
    condition     = length(aws_api_gateway_method.options) == 0
    error_message = "OPTIONS method created when CORS is disabled"
  }
}

run "test_cors_custom_origins" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      cors = {
        allow_origins     = ["https://example.com", "https://test.com"]
        allow_methods     = ["GET", "POST"]
        allow_headers     = ["Content-Type"]
        expose_headers    = []
        max_age           = 7200
        allow_credentials = true
      }
    }

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
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == "'https://example.com,https://test.com'"
    error_message = "Custom CORS configuration for Allow-Origin not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST'"
    error_message = "Custom CORS configuration for Allow-Methods not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Credentials"] == "'true'"
    error_message = "Custom CORS configuration for Allow-Credentials not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'7200'"
    error_message = "Custom CORS configuration for Max-Age not applied correctly"
  }
}

run "test_cors_defaults" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    rest_api = {
      cors = {
        allow_origins : ["*"]
      }
    }

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
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST,PUT,DELETE,OPTIONS'"
    error_message = "Default CORS configuration for Allow-Methods not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Headers"] == "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    error_message = "Default CORS configuration for Allow-Headers not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Expose-Headers"] == "''"
    error_message = "Default CORS configuration for Expose-Headers not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'3600'"
    error_message = "Default CORS configuration for Max-Age not applied correctly"
  }

  assert {
    condition     = aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Credentials"] == "'false'"
    error_message = "Default CORS configuration for Allow-Credentials not applied correctly"
  }
}