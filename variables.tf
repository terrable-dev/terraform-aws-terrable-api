variable "api_name" {
  type = string
}

variable "handlers" {
  type = map(object({
    source : string
    policies : optional(map(string))
    environment_variables : optional(map(string))
    http = map(string)
  }))

  validation {
  condition = alltrue([
    for handler in values(var.handlers) :
    alltrue([
      for method in keys(handler.http) :
      contains(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "ANY"], upper(method))
    ])
  ])
  error_message = "The HTTP methods must be one of GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS or ANY."
}
}

variable "http_api" {
  type = object({
    custom_domain : optional(string)
    certificate_arn : optional(string)
  })

  default = null
}

variable "global_policies" {
  type    = map(string)
  default = {}
}

variable "global_environment_variables" {
  type    = map(string)
  default = {}
}
