variable "api_name" {
  type = string
}

variable "vpc" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = {
    subnet_ids         = []
    security_group_ids = []
  }
}

variable "handlers" {
  type = map(object({
    source : string
    policies : optional(map(string))
    environment_variables : optional(map(string))
    http = map(string)
    tags = optional(map(string))
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

variable "rest_api" {
  type = object({
    custom_domain : optional(string)
    certificate_arn : optional(string)
    tags : optional(map(string))
    endpoint_type : optional(string, "REGIONAL")
  })
  default = null

  validation {
    condition = var.rest_api == null ? true : (
      var.rest_api.endpoint_type == null || contains(["REGIONAL", "PRIVATE"], var.rest_api.endpoint_type)
    )
    error_message = "The endpoint_type must be either 'REGIONAL' or 'PRIVATE'."
  } 
}

variable "http_api" {
  type = object({
    custom_domain : optional(string)
    certificate_arn : optional(string)
    tags : optional(map(string))
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
