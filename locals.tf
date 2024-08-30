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
    }

    if try(handler.http, null) != null
  }
}

locals {
  http_custom_domain = try(var.httpApi.custom_domain, null)
  create_certificate = try(var.httpApi.custom_domain, null) != null && try(var.httpApi.certificate_arn, null) == null
}
