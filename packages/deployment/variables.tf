variable "ssl_cert_arn" {
  description = "ARN of Certificate Manager certificate"
}

variable "root_domain" {
  description = "Desired root domain name for API; e.g. 'example.com' for 'api.example.com'"
}

variable "subdomain" {
  description = "Desired subdomain; e.g. 'api' for 'api.example.com'"
}
