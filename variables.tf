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
    environment_variables : optional(map(object({
      value = optional(string)
      ssm   = optional(string)
    })))
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

  validation {
    condition = alltrue([
      for handler in values(var.handlers) :
      handler.environment_variables == null ? true : alltrue([
        for k, v in handler.environment_variables :
        v == null || can(tostring(v)) || (
          can(v.ssm) && can(tostring(v.ssm))
        )
      ])
    ])

    error_message = "Environment variables must be strings or objects containing an 'ssm' reference."
  }
}

variable "rest_api" {
  type = object({
    custom_domain : optional(string)
    certificate_arn : optional(string)
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
  type = map(object({
    value = optional(string)
    ssm   = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in var.global_environment_variables :
      (v.value != null && v.ssm == null) || (v.value == null && v.ssm != null)
    ])
    error_message = "Each environment variable must have either a 'value' OR an 'ssm' property, but not both."
  }
}