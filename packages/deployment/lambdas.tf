locals {
  api_hostname         = "${var.subdomain}.${var.root_domain}"
  allowed_origin_hosts = "${var.frontend_hostname},${local.api_hostname}"
}

resource "aws_lambda_function" "graphql" {
  function_name = "${var.app_name}-graphql"

  filename         = "${path.module}/bundles/server.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/server.zip"))}"

  handler = "index.graphql"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true

  vpc_config = {
    security_group_ids = [
      "${data.aws_security_group.default.id}",
      "${data.aws_security_group.redis.id}",
    ]

    subnet_ids = ["${data.aws_subnet_ids.private.ids}"]
  }

  environment {
    variables = {
      FRONTEND_ORIGIN      = "https://${var.frontend_hostname}"
      AUTH0_DOMAIN         = "${data.aws_ssm_parameter.auth0_domain.value}"
      AUTH0_CLIENT_ID      = "${data.aws_ssm_parameter.auth0_client_id.value}"
      AUTH0_CLIENT_SECRET  = "${data.aws_ssm_parameter.auth0_client_secret.value}"
      ALLOWED_ORIGIN_HOSTS = "${local.allowed_origin_hosts}"
      CALLBACK_URL         = "https://${local.api_hostname}/login"
      REDIS_HOST           = "${aws_elasticache_cluster.cache.cache_nodes.0.address}"
      REDIS_PORT           = "${aws_elasticache_cluster.cache.cache_nodes.0.port}"
      FRONTEND_LOCATION    = "https://${var.frontend_hostname}${var.frontend_path}"
    }
  }

  tags {
    App = "${var.app_name}"
  }
}

resource "aws_lambda_function" "cors" {
  function_name = "${var.app_name}-cors"

  filename         = "${path.module}/bundles/cors.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/cors.zip"))}"

  handler = "index.cors"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true

  environment {
    variables = {
      FRONTEND_ORIGIN      = "https://${var.frontend_hostname}"
      ALLOWED_ORIGIN_HOSTS = "${local.allowed_origin_hosts}"
    }
  }

  tags {
    App = "${var.app_name}"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.app_name}-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "cloudwatch-log-group-lambda" {
  statement {
    actions = [
      "logs:PutLogEvents",    # take care of action order
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "lambda_cloudwatch" {
  name        = "${var.app_name}-lambda-cloudwatch"
  description = "Give Lambdas access to Cloudwatch"
  policy      = "${data.aws_iam_policy_document.cloudwatch-log-group-lambda.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_cloudwatch.arn}"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "login" {
  function_name = "${var.app_name}-login"

  filename         = "${path.module}/bundles/auth.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/auth.zip"))}"

  handler = "index.login"
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

module "graphiql_resource" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.graphql.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  resource_path_part        = "graphql"
  http_method               = "GET"
  create_resource           = false
  parent_resource_id        = "${module.graphql_lambda_resource.resource_id}"
}

module "graphql_lambda_resource" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.graphql.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  resource_path_part        = "graphql"
  http_method               = "POST"
}

module "graphql_cors" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.cors.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  create_resource           = false
  parent_resource_id        = "${module.graphql_lambda_resource.resource_id}"
  resource_path_part        = "graphql"
  http_method               = "OPTIONS"
}

module "login_lambda_resource" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.login.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  resource_path_part        = "login"
  http_method               = "GET"
}
