mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  api_name        = "test-api"
  global_policies = ["arn:aws:iam::aws:policy/GlobalPolicy1", "arn:aws:iam::aws:policy/GlobalPolicy2"]
  handlers = {
    TestHandlerOne : {
      policies = ["arn:aws:iam::aws:policy/HandlerOne"]
      source   = "./tests/handler.js"
      http = {
        method = "GET"
        path   = "/1"
      }
    }
    TestHandlerTwo : {
      policies = ["arn:aws:iam::aws:policy/HandlerTwo"]
      source   = "./tests/handler.js"
      http = {
        method = "GET"
        path   = "/2"
      }
    }
    TestHandlerCombined : {
      policies = ["arn:aws:iam::aws:policy/HandlerOne", "arn:aws:iam::aws:policy/HandlerTwo"]
      source   = "./tests/handler.js"
      http = {
        method = "GET"
        path   = "/3"
      }
    }
  }
}

run "test_TestHandlerOne_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerOne-arn:aws:iam::aws:policy/HandlerOne"].policy_arn == "arn:aws:iam::aws:policy/HandlerOne"
    error_message = "TestHandlerOne does not have the expected HandlerOne policy attached"
  }

  assert {
    condition     = !contains(keys(aws_iam_role_policy_attachment.handler_policies), "TestHandlerOne-arn:aws:iam::aws:policy/HandlerTwo")
    error_message = "TestHandlerOne should not have a HandlerTwo policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerOne-arn:aws:iam::aws:policy/GlobalPolicy1"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerOne does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerOne-arn:aws:iam::aws:policy/GlobalPolicy2"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerOne does not have the expected GlobalPolicy2 policy attached"
  }
}

run "test_TestHandlerTwo_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerTwo-arn:aws:iam::aws:policy/HandlerTwo"].policy_arn == "arn:aws:iam::aws:policy/HandlerTwo"
    error_message = "TestHandlerTwo does not have the expected HandlerTwo policy attached"
  }

  assert {
    condition     = !contains(keys(aws_iam_role_policy_attachment.handler_policies), "TestHandlerTwo-arn:aws:iam::aws:policy/HandlerOne")
    error_message = "TestHandlerTwo should not have a HandlerOne policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerTwo-arn:aws:iam::aws:policy/GlobalPolicy1"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerTwo does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerTwo-arn:aws:iam::aws:policy/GlobalPolicy2"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerTwo does not have the expected GlobalPolicy2 policy attached"
  }
}

run "test_TestHandlerCombined_policies" {
  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerCombined-arn:aws:iam::aws:policy/HandlerOne"].policy_arn == "arn:aws:iam::aws:policy/HandlerOne"
    error_message = "TestHandlerCombined does not have the expected HandlerOne policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.handler_policies["TestHandlerCombined-arn:aws:iam::aws:policy/HandlerTwo"].policy_arn == "arn:aws:iam::aws:policy/HandlerTwo"
    error_message = "TestHandlerCombined does not have the expected HandlerTwo policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerCombined-arn:aws:iam::aws:policy/GlobalPolicy1"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy1"
    error_message = "TestHandlerCombined does not have the expected GlobalPolicy1 policy attached"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.global_policies["TestHandlerCombined-arn:aws:iam::aws:policy/GlobalPolicy2"].policy_arn == "arn:aws:iam::aws:policy/GlobalPolicy2"
    error_message = "TestHandlerCombined does not have the expected GlobalPolicy2 policy attached"
  }
}
