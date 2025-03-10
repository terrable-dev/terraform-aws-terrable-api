mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/example-role"
  }
}

mock_resource "aws_lambda_permission" {
  defaults = {
    arn = "arn:aws:apigateway:eu-west-2::/apis/y49wdbfoad"
  }
}

mock_resource "aws_lambda_function" {
  defaults = {
    arn = "arn:aws:lambda:us-east-1:123456789012:function:test-function"
    invoke_arn = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:test-function/invocations"
  }
}

mock_resource "aws_apigatewayv2_api" {
  defaults = {
    execution_arn = "arn:aws:execute-api:us-east-1:123456789012:abcdef123"
  }
}

mock_resource "aws_apigatewayv2_api_mapping" {
  defaults = {
    api_id      = "abcdef123456"
    domain_name = "testdomain.test.com"
    stage       = "$default"
  }
}

mock_resource "aws_apigatewayv2_stage" {
  defaults = {
    name        = "$default"
    auto_deploy = true
  }
}

mock_resource "aws_route53_record" {
  defaults = {
    name = "testdomain.test.com"
  }
}

mock_resource "aws_apigatewayv2_domain_name" {
  defaults = {
    id          = "abcdef123456"
    domain_name = "testdomain.test.com"
    domain_name_configuration = {
      endpoint_type      = "REGIONAL"
      target_domain_name = "d-abcde12345.execute-api.us-east-1.amazonaws.com"
      hosted_zone_id     = "Z2FDTNDATAQYW2"
    }
  }
}

mock_resource "aws_acm_certificate" {
  defaults = {
    arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    domain_validation_options = [
      {
        domain_name           = "testdomain.test.com"
        resource_record_name  = "_amazonses.testdomain.test.com"
        resource_record_type  = "TXT"
        resource_record_value = "verification_token"
      }
    ]
  }
}

# API Gateway V1
mock_resource "aws_api_gateway_rest_api" {
  defaults = {
    execution_arn = "arn:aws:execute-api:us-west-2:123456789012:abcdef123"
  }
}

# Mock for SSM parameters
mock_data "aws_ssm_parameter" {
  defaults = {
    name  = "/mocked-ssm"
    value = "ssm-mocked-value"
  }
}

# Mock for cloudwatch event rule
mock_resource "aws_cloudwatch_event_rule" {
  defaults = {
    arn = "arn:aws:events:us-east-1:123456789012:rule/ScheduledHandler-scheduled"
  }
}

# Cloudwatch event target
mock_resource "aws_cloudwatch_event_target" {
  defaults = {
    arn = "arn:aws:events:us-east-1:123456789012:rule/ScheduledHandler-scheduled"
  }
}
