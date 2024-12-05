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
    hosted_zone_id : optional(string)
    tags : optional(map(string))
    endpoint_type : optional(string, "REGIONAL")
    vpc_endpoint_ids : optional(list(string))
  })
  default = null

  validation {
    condition = var.rest_api == null ? true : (
      var.rest_api.endpoint_type == null || contains(["REGIONAL", "PRIVATE"], var.rest_api.endpoint_type)
    )
    error_message = "The endpoint_type must be either 'REGIONAL' or 'PRIVATE'."
  }

  validation {
    condition = var.rest_api == null ? true : (
      var.rest_api.custom_domain == null ? true : var.rest_api.hosted_zone_id != null
    )
    error_message = "hosted_zone_id is required when custom_domain is specified."
  }
}

variable "http_api" {
  type = object({
    custom_domain : optional(string)
    hosted_zone_id : optional(string)
    tags : optional(map(string))
  })
  default = null

  validation {
    condition = var.http_api == null ? true : (
      var.http_api.custom_domain == null ? true : var.http_api.hosted_zone_id != null
    )
    error_message = "hosted_zone_id is required when custom_domain is specified."
  }
}

variable "global_policies" {
  type    = map(string)
  default = {}
}

variable "global_environment_variables" {
  type    = map(string)
  default = {}
}