resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  for_each = {
    for name, handler in var.handlers : name => handler.sqs
    if handler.sqs != null
  }

  event_source_arn = each.value.queue
  function_name    = aws_lambda_function.handlers[each.key].arn
  batch_size       = each.value.batch_size
  enabled          = true

  depends_on = [aws_iam_role_policy.sqs_policy]

  scaling_config {
    maximum_concurrency = each.value.maximum_concurrency
  }
}

resource "aws_iam_role_policy" "sqs_policy" {
  for_each = {
    for name, handler in var.handlers : name => handler.sqs
    if handler.sqs != null
  }

  name = "sqs-permissions-${each.key}"
  role = split("/", aws_lambda_function.handlers[each.key].role)[1]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSPermissions"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [each.value.queue]
      }
    ]
  })
}