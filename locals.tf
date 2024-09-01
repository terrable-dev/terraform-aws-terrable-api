locals {
  handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name   = handler_name
      source = handler.source
    }
  }

  http_handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name   = handler_name,
      source = handler.source,
      http   = try(handler.http, null),
      environment_vars = merge(coalesce(var.global_environment_variables, {}), coalesce(handler.environment_variables, {}))
    }

    if try(handler.http, null) != null
  }
}

locals {
  http_custom_domain = try(var.http_api.custom_domain, null)
  create_certificate = try(var.http_api.custom_domain, null) != null && try(var.http_api.certificate_arn, null) == null
}
