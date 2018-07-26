# # Required data

data "aws_ssm_parameter" "auth0_domain" {
  name = "auth0_domain"
}

data "aws_ssm_parameter" "auth0_client_id" {
  name = "auth0_client_id"
}

data "aws_ssm_parameter" "auth0_client_secret" {
  name = "auth0_client_secret"
}
