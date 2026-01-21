# Network Load Balancer for Databricks Serverless → dbx-proxy
resource "aws_lb" "this" {
  count = var.bootstrap_load_balancer ? 1 : 0

  name               = "${var.prefix}-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  count = local.nlb_has_security_groups ? length(local.nlb_sg_egress_rules) : 0

  security_group_id = local.nlb_sg_egress_rules[count.index].security_group_id
  from_port         = local.nlb_sg_egress_rules[count.index].port
  to_port           = local.nlb_sg_egress_rules[count.index].port
  ip_protocol       = "tcp"
  cidr_ipv4         = local.nlb_sg_egress_rules[count.index].cidr
  description       = local.nlb_sg_egress_rules[count.index].description
}

# Optional: expose the dbx-proxy health port via the NLB so callers can reach it directly
# (e.g. through the PrivateLink endpoint). If the health port is already used as a regular
# listener port, we skip creating this additional listener/TG to avoid a conflict.
resource "aws_lb_target_group" "health" {
  count = contains([for l in var.dbx_proxy_listener : l.port], var.dbx_proxy_health_port) ? 0 : 1

  name        = "dbx-proxy-tg-health"
  port        = var.dbx_proxy_health_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "HTTP"
    port                = var.dbx_proxy_health_port
    path                = "/status"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = var.tags
}

resource "aws_lb_listener" "health" {
  count = length(aws_lb_target_group.health)

  load_balancer_arn = local.nlb_arn
  port              = var.dbx_proxy_health_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.health[0].arn
  }
}

# One target group per listener port for simple configuration.
resource "aws_lb_target_group" "this" {
  for_each = { for l in var.dbx_proxy_listener : l.name => l }

  name        = "dbx-proxy-tg-${each.key}"
  port        = each.value.port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = upper(each.value.mode)
    port                = var.dbx_proxy_health_port
    path                = each.value.mode == "http" ? "/status" : null
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = var.tags
}

resource "aws_lb_listener" "this" {
  for_each = aws_lb_target_group.this

  load_balancer_arn = local.nlb_arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)

  default_action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
}
