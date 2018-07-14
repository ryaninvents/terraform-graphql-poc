resource "aws_api_gateway_domain_name" "example" {
  certificate_arn = "${var.ssl_cert_arn}"
  domain_name     = "${var.subdomain}.${var.root_domain}"
}

data "aws_route53_zone" "zone" {
  name = "${var.root_domain}"
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.zone.id}"
  name    = "${aws_api_gateway_domain_name.example.domain_name}"
  type    = "A"

  alias {
    name    = "${aws_api_gateway_domain_name.example.cloudfront_domain_name}"
    zone_id = "${aws_api_gateway_domain_name.example.cloudfront_zone_id}"

    evaluate_target_health = true
  }
}

resource "aws_api_gateway_base_path_mapping" "example" {
  api_id      = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "${aws_api_gateway_deployment.example.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.example.domain_name}"
}
