variable "api_name" {
  type = string
}

variable "runtime" {
  type        = string
  description = "Default runtime for all handlers if not specified individually"
  default     = null
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

variable "log_retention_days" {
  type        = number
  description = "The number of days that log events should be retained for in any created CloudWatch log groups."
  default     = 0

  validation {
    condition     = var.log_retention_days == null || contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of the following values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, or null."
  }

  validation {
    condition     = var.log_retention_days == null || var.log_retention_days >= 0
    error_message = "log_retention_days must be greater than or equal to 0 if specified."
  }
}

variable "handlers" {
  type = map(object({
    source : string
    policies : optional(map(string))
    environment_variables : optional(map(string))
    http    = map(string)
    tags    = optional(map(string))
    runtime = optional(string)
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
    condition = var.runtime != null ? true : alltrue([
      for handler in values(var.handlers) :
      handler.runtime != null
    ])
    error_message = "Runtime configuration error: No global runtime specified and the following handlers are missing a runtime: ${join(", ", [for name, handler in var.handlers : name if handler.runtime == null])}"
  }
}


variable "rest_api" {
  type = object({
    custom_domain    = optional(string)
    hosted_zone_id   = optional(string)
    tags             = optional(map(string))
    endpoint_type    = optional(string, "REGIONAL")
    vpc_endpoint_ids = optional(list(string))
    runtime          = optional(string)
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
    custom_domain  = optional(string)
    hosted_zone_id = optional(string)
    tags           = optional(map(string))
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