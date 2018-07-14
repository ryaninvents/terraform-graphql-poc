resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  filename         = "${path.module}/bundles/server.zip"
  source_code_hash = "${base64sha256(file("${path.module}/bundles/server.zip"))}"

  handler = "index.handler"
  runtime = "nodejs8.10"

  role = "${aws_iam_role.lambda_exec.arn}"
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
