resource "aws_api_gateway_rest_api" "example" {
  name        = "${var.app_name}"
  description = "Terraform GraphQL Proof-Of-Concept"
}

locals {
  lambda_integrations = [
    "${module.graphql_lambda_resource.resource_id}",
    "${module.graphiql_lambda_resource.resource_id}",
    "${module.login_lambda_resource.resource_id}",
  ]

  lambda_source_hashes = [
    "${aws_lambda_function.graphql.source_code_hash}",
    "${aws_lambda_function.graphiql.source_code_hash}",
    "${aws_lambda_function.login.source_code_hash}",
  ]

  lambda_source_hash = "${
    base64sha256(join("|", local.lambda_source_hashes))
  }"
}

resource "null_resource" "api_gateway_deployment_trigger" {
  triggers = {
    integrations = "${join(",", local.lambda_integrations)}"
  }
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    "null_resource.api_gateway_deployment_trigger",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  description = "${join(",", local.lambda_integrations)}"
  stage_name  = "test"

  variables = {
    integrations = "${join(",", local.lambda_integrations)}"
    source_hash  = "${replace(local.lambda_source_hash, "+", ".")}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "apigw_graphql" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.graphql.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_graphiql" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.graphiql.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_login" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.login.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
}

output "base_api_url" {
  value = "https://${local.api_hostname}"
}

output "graphiql_url" {
  value = "https://${local.api_hostname}/graphiql"
}
