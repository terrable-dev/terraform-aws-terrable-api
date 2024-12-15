mock_provider "aws" {
  source = "./tests/mocks"
}

run "test_cors_configuration_v2" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    http_api = {
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
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_origins) == toset(["*"])
    error_message = "CORS allow_origins not set correctly"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_methods) == toset(["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    error_message = "CORS allow_methods not set correctly"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_headers) == toset(["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"])
    error_message = "CORS allow_headers not set correctly"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].expose_headers) == toset(["Content-Length", "X-My-Header"])
    error_message = "CORS expose_headers not set correctly"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].max_age == 3600
    error_message = "CORS max_age not set correctly"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_credentials == false
    error_message = "CORS allow_credentials not set correctly"
  }
}

run "test_cors_disabled_v2" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"
    http_api = {}

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
    condition     = length(aws_apigatewayv2_api.api_gateway[0].cors_configuration) == 0
    error_message = "CORS configuration created when it should be disabled"
  }
}

run "test_cors_custom_origins_v2" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    http_api = {
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
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_origins) == toset(["https://example.com", "https://test.com"])
    error_message = "CORS allow_origins not set correctly for custom origins"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_methods) == toset(["GET", "POST"])
    error_message = "CORS allow_methods not set correctly for custom configuration"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_headers) == toset(["Content-Type"])
    error_message = "CORS allow_headers not set correctly for custom configuration"
  }

  assert {
    condition     = length(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].expose_headers) == 0
    error_message = "CORS expose_headers should be empty for this custom configuration"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].max_age == 7200
    error_message = "CORS max_age not set correctly for custom configuration"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_credentials == true
    error_message = "CORS allow_credentials not set correctly for custom configuration"
  }
}

run "test_cors_defaults_v2" {
  variables {
    api_name = "test-api"
    runtime  = "nodejs20.x"

    http_api = {
      cors = {
        allow_origins = ["*"]
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
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_origins) == toset(["*"])
    error_message = "CORS allow_origins not set correctly for default configuration"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_methods) == toset(["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    error_message = "CORS allow_methods not set to default values"
  }

  assert {
    condition     = toset(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_headers) == toset(["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"])
    error_message = "CORS allow_headers not set to default values"
  }

  assert {
    condition     = length(aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].expose_headers) == 0
    error_message = "CORS expose_headers should be empty by default"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].max_age == 3600
    error_message = "CORS max_age not set to default value"
  }

  assert {
    condition     = aws_apigatewayv2_api.api_gateway[0].cors_configuration[0].allow_credentials == false
    error_message = "CORS allow_credentials not set to default value"
  }
}