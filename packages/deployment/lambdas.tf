resource "aws_lambda_function" "graphql" {
  function_name = "terraform-graphql-poc-graphql"

  filename         = "${path.module}/bundles/server.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/server.zip"))}"

  handler = "index.graphql"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true

  environment {
    variables = {
      FRONTEND_ORIGIN = "https://${var.frontend_hostname}"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

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
  name        = "terraform-graphql-poc"
  description = "Give Lambdas access to Cloudwatch"
  policy      = "${data.aws_iam_policy_document.cloudwatch-log-group-lambda.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${aws_iam_policy.lambda_cloudwatch.arn}"
}

resource "aws_lambda_function" "example" {
  function_name = "terraform-graphql-poc-example"

  filename         = "${path.module}/bundles/server.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/server.zip"))}"

  handler = "index.handler"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true
}

resource "aws_lambda_function" "graphiql" {
  function_name = "terraform-graphql-poc-graphiql"

  filename         = "${path.module}/bundles/server.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/server.zip"))}"

  handler = "index.graphiql"
  runtime = "nodejs8.10"

  role    = "${aws_iam_role.lambda_exec.arn}"
  publish = true
}

resource "aws_lambda_permission" "apigw_example" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
}

module "example_lambda_resource" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.example.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  resource_path_part        = "example"
  http_method               = "GET"
}

module "graphiql_lambda_resource" {
  source = "./api-endpoint"

  lambda_invoke_arn         = "${aws_lambda_function.graphiql.invoke_arn}"
  rest_api_id               = "${aws_api_gateway_rest_api.example.id}"
  rest_api_root_resource_id = "${aws_api_gateway_rest_api.example.root_resource_id}"
  resource_path_part        = "graphiql"
  http_method               = "GET"
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
  source  = "mewa/apigateway-cors/aws"
  version = "1.0.0"

  api      = "${aws_api_gateway_rest_api.example.id}"
  resource = "${module.graphql_lambda_resource.resource_id}"
  origin   = "https://${var.frontend_hostname}"
  methods  = ["POST"]
}
