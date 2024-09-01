variable "api_name" {
  type = string
}

variable "handlers" {
  type = map(object({
    source : string
    policies : optional(map(string))
    environment_variables : optional(map(string))
    http = object({
      path : string
      method : string
    })
  }))
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
  type = map(string)
  default = {}
}
