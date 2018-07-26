variable "lambda_invoke_arn" {
  description = "Invocation ARN of lambda to attach"
}

variable "create_resource" {
  description = "Set to 'true' to create the resource, 'false' otherwise"
  default     = true
}

variable "rest_api_id" {
  description = "ID of the rest API"
}

variable "rest_api_root_resource_id" {
  description = "Root resource ID for the rest API"
}

variable "parent_resource_id" {
  description = "Parent resource"
  default     = "ATTACH_TO_ROOT"
}

variable "resource_path_part" {}

variable "http_method" {
  description = "All-caps HTTP verb"
}

variable "authorization" {
  default = "NONE"
}

variable "authorizer_id" {
  default = ""
}

# # Resources

locals {
  parent_resource_id = "${var.parent_resource_id == "ATTACH_TO_ROOT" ? var.rest_api_root_resource_id : var.parent_resource_id}"

  attached_resource_id = "${
    var.create_resource == 1
      ? element(concat(aws_api_gateway_resource.resource.*.id, list("")), 0)
      : local.parent_resource_id
  }"
}

resource "aws_api_gateway_resource" "resource" {
  count       = "${var.create_resource ? 1 : 0}"
  rest_api_id = "${var.rest_api_id}"
  parent_id   = "${local.parent_resource_id}"
  path_part   = "${var.resource_path_part}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${var.rest_api_id}"
  http_method   = "${var.http_method}"
  authorization = "${var.authorization}"
  authorizer_id = "${var.authorizer_id}"
  resource_id   = "${local.attached_resource_id}"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${var.rest_api_id}"
  resource_id = "${aws_api_gateway_method.method.resource_id}"
  http_method = "${aws_api_gateway_method.method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${var.lambda_invoke_arn}"
}

output "resource_id" {
  value = "${local.attached_resource_id}"
}
