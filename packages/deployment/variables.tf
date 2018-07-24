variable "ssl_cert_arn" {
  description = "ARN of Certificate Manager certificate"
}

variable "root_domain" {
  description = "Desired root domain name for API; e.g. 'example.com' for 'api.example.com'"
}

variable "subdomain" {
  description = "Desired subdomain; e.g. 'api' for 'api.example.com'"
}

variable "frontend_hostname" {
  description = "Hostname where the frontend is deployed"
}

variable "app_name" {
  description = "Application name; used to generate resource names and tags. Use hyphens, not underscores"
}
