mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name = "test-api"
  rest_api = {
    tags = {
      rest_api_tag1 = "rest_api_tag_value1"
      rest_api_tag2 = "rest_api_tag_value2"
    }
  }
  handlers = {
    TestHandler : {
      source = "./tests/handler.js"
      http = {
        GET = "/"
      }
      tags = {
        TestHandlerTag1Key = "TestHandlerTag1Value"
        TestHandlerTag2Key = "TestHandlerTag2Value"
      }
    }
  }
}

run "lambda_function_tags" {
  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].tags["TestHandlerTag1Key"] == "TestHandlerTag1Value"
    error_message = "Tag TestHandlerTag1Key not set with TestHandlerTag1Value"
  }

  assert {
    condition     = aws_lambda_function.handlers["TestHandler"].tags["TestHandlerTag2Key"] == "TestHandlerTag2Value"
    error_message = "Tag TestHandlerTag2Key not set with TestHandlerTag2Value"
  }
}

run "rest_api_tags" {
  assert {
    condition     = aws_api_gateway_rest_api.api_gateway[0].tags["rest_api_tag1"] == "rest_api_tag_value1"
    error_message = "Tag rest_api_tag1 not set with rest_api_tag_value1"
  }

  assert {
    condition     = aws_api_gateway_rest_api.api_gateway[0].tags["rest_api_tag2"] == "rest_api_tag_value2"
    error_message = "Tag rest_api_tag2 not set with rest_api_tag_value2"
  }
}
