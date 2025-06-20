locals {
  api_gateway_version = var.http_api != null ? "v2" : var.rest_api != null ? "v1" : "v2"
}

locals {
  handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name             = handler_name,
      source           = handler.source,
      http             = try(handler.http, null),
      sqs              = try(handler.sqs, null),
      environment_vars = coalesce(var.environment_vars, {})
      tags             = handler.tags != null ? handler.tags : {}
      policies         = handler.policies
    }
  }

  http_handlers = {
    for handler_name, handler in local.handlers : handler_name => handler
    if handler.http != null && local.api_gateway_version == "v2"
  }

  rest_handlers = {
    for handler_name, handler in local.handlers : handler_name => handler
    if handler.http != null && local.api_gateway_version == "v1"
  }
}

locals {
  custom_domain      = try(var.http_api.custom_domain, var.rest_api.custom_domain, null)
  create_domain      = try(local.custom_domain, null) != null && (try(var.rest_api, null) != null ? var.rest_api.endpoint_type != "PRIVATE" : true)
  create_certificate = try(local.custom_domain, null) != null
}
