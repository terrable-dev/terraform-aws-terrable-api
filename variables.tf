variable "api_name" {
  type = string
}

variable "handlers" {
  type = map(object({
    source : string
    policies : optional(list(string))
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
  type = list(string)
  default = []
}

