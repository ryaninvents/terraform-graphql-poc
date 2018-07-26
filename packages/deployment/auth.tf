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

data "aws_region" "current" {}

# # The lambda function itself

resource "aws_lambda_function" "auth" {
  function_name = "${var.app_name}-auth"

  filename         = "${path.module}/bundles/auth.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/auth.zip"))}"

  handler = "index.authorizer"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true

  tags {
    App = "${var.app_name}"
  }

  vpc_config = {
    security_group_ids = [
      "${data.aws_security_group.default.id}",
      "${data.aws_security_group.redis.id}",
    ]

    subnet_ids = ["${data.aws_subnet_ids.private.ids}"]
  }

  environment {
    variables = {
      AUTH0_DOMAIN        = "${data.aws_ssm_parameter.auth0_domain.value}"
      AUTH0_CLIENT_ID     = "${data.aws_ssm_parameter.auth0_client_id.value}"
      AUTH0_CLIENT_SECRET = "${data.aws_ssm_parameter.auth0_client_secret.value}"
      CALLBACK_URL        = "https://${local.api_hostname}/login"
      REDIS_HOST          = "${aws_elasticache_cluster.cache.cache_nodes.0.address}"
      REDIS_PORT          = "${aws_elasticache_cluster.cache.cache_nodes.0.port}"
      FRONTEND_ORIGIN     = "https://${var.frontend_hostname}"
    }
  }
}

# # Authorizer and roles

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "${var.app_name}-auth"
  rest_api_id            = "${aws_api_gateway_rest_api.example.id}"
  authorizer_uri         = "${aws_lambda_function.auth.invoke_arn}"
  authorizer_credentials = "${aws_iam_role.invocation_role.arn}"
  identity_source        = "method.request.header.Cookie"
}

resource "aws_iam_role" "invocation_role" {
  name = "${var.app_name}-invocation"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "${var.app_name}-invocation"
  role = "${aws_iam_role.invocation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.auth.arn}"
    }
  ]
}
EOF
}
