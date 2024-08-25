variable "api_name" {
  type = string
}

variable "handlers" {
  type = map(object({
    source : string
    http = object({
      path : string
      method : string
    })
  }))
}
