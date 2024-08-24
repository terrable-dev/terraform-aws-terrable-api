locals {
  handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name   = handler_name
      source = handler.source
    }
  }

  http_handlers = {
    for handler_name, handler in var.handlers : handler_name => {
      name = handler_name,
      source = handler.source,
      http = try(handler.http, null),
    }

    if try(handler.http, null) != null
  }
}
