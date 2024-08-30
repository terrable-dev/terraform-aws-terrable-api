resource "aws_iam_role" "lambda_role" {
  name = "${var.api_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Base permissions

resource "aws_lambda_permission" "lambda_api_gateway_execution_permission" {
  for_each = var.handlers

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handlers[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "lambda_log_groups" {
  for_each = local.handlers

  name              = "/aws/lambda/${aws_lambda_function.handlers[each.key].function_name}"
  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# User-provided policies

resource "aws_iam_role_policy_attachment" "global_policies" {
  for_each = {
    for pair in flatten([
      for handler_key, handler in var.handlers : [
        for policy in coalesce(var.global_policies, []) : {
          key         = "${handler_key}-${policy}"
          handler_key = handler_key
          policy      = policy
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value.policy
}

resource "aws_iam_role_policy_attachment" "handler_policies" {
  for_each = {
    for pair in flatten([
      for handler_key, handler in var.handlers : [
        for policy in coalesce(handler.policies, []) : {
          key         = "${handler_key}-${policy}"
          handler_key = handler_key
          policy      = policy
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value.policy
}
