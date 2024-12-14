mock_provider "aws" {
  source = "./tests/mocks"
}

run "test_cors_configuration" {
  variables {
    api_name = "test-api"
    runtime = "nodejs20.x"
    rest_api = {
      cors = {
        allow_origins     = ["*"]
        allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
        expose_headers    = ["Content-Length", "X-My-Header"]
        max_age          = 3600
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

  # Test ROOT path OPTIONS configuration
  assert {
    condition = (
      aws_api_gateway_method.options["/"].http_method == "OPTIONS" &&
      aws_api_gateway_method.options["/"].authorization == "NONE"
    )
    error_message = "Root OPTIONS method not configured correctly"
  }

  # Test response parameters for root OPTIONS
  assert {
    condition = (
      aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Headers"] == true &&
      aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == true &&
      aws_api_gateway_method_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == true
    )
    error_message = "Root OPTIONS method response headers not configured correctly"
  }

  # Test MOCK integration type for root
  assert {
    condition = aws_api_gateway_integration.options["/"].type == "MOCK"
    error_message = "Integration type is not MOCK"
  }

  # Test integration response parameters for root
  assert {
    condition = (
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == "'*'" &&
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST,PUT,DELETE,OPTIONS'" &&
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'3600'"
    )
    error_message = "Root OPTIONS integration response parameters not configured correctly"
  }
}


# Test CORS disabled
run "test_cors_disabled" {
  variables {
    api_name = "test-api"
    runtime = "nodejs20.x"
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
    condition = length(aws_api_gateway_method.options) == 0
    error_message = "OPTIONS method created when CORS is disabled"
  }
}

# Test CORS with custom origins
run "test_cors_custom_origins" {
  variables {
    api_name = "test-api"
        runtime = "nodejs20.x"

    rest_api = {
      cors = {
        allow_origins     = ["https://example.com", "https://test.com"]
        allow_methods     = ["GET", "POST"]
        allow_headers     = ["Content-Type"]
        expose_headers    = []
        max_age          = 7200
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
    condition = (
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Origin"] == "'https://example.com,https://test.com'" &&
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST'" &&
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Credentials"] == "'true'" &&
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'7200'"
    )
    error_message = "Custom CORS configuration not applied correctly"
  }
}

run "test_cors_defaults" {
  variables {
    api_name = "test-api"
        runtime = "nodejs20.x"

    rest_api = {
      cors = {
        allow_origins: ["*"]
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
    condition = (
      # Default allow_methods should be ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Methods"] == "'GET,POST,PUT,DELETE,OPTIONS'" &&
      # Default allow_headers should be ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"]
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Headers"] == "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'" &&
      # Default expose_headers should be []
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Expose-Headers"] == "''" &&
      # Default max_age should be 3600
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Max-Age"] == "'3600'" &&
      # Default allow_credentials should be false
      aws_api_gateway_integration_response.options["/"].response_parameters["method.response.header.Access-Control-Allow-Credentials"] == "'false'"
    )
    error_message = "Default CORS configuration not applied correctly"
  }
}