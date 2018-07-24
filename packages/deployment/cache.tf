data "aws_vpc" "default" {
  default = true
}

# data "aws_security_group" "redis" {
#   vpc_id = "${data.aws_vpc.default.id}"
#   name   = "redis"
# }

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

data "aws_security_group" "redis" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "redis"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.default.id}"

  tags {
    Type = "private"
  }
}

resource "aws_elasticache_parameter_group" "default" {
  name   = "${var.app_name}-params"
  family = "redis4.0"
}

resource "aws_elasticache_cluster" "cache" {
  cluster_id           = "${var.app_name}-cache"
  engine               = "redis"
  node_type            = "cache.t2.small"
  parameter_group_name = "${aws_elasticache_parameter_group.default.name}"
  port                 = 6379
  num_cache_nodes      = 1

  security_group_ids = ["${data.aws_security_group.redis.id}"]
}
