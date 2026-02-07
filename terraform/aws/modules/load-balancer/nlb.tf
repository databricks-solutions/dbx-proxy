# Network Load Balancer for Databricks Serverless → dbx-proxy
resource "aws_lb" "this" {
  count = var.bootstrap_load_balancer ? 1 : 0

  name               = "${var.prefix}-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.this[0].id]

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  # PrivateLink traffic bypasses NLB SG ingress when this is off. We use off
  # because the service owner cannot restrict ingress by endpoint SG/CIDR without
  # consumer-provided details; access is instead controlled via endpoint service
  # allowed_principals and manual acceptance.
  enforce_security_group_inbound_rules_on_private_link_traffic = "off"

  tags = var.tags
}

resource "aws_security_group" "this" {
  count = var.bootstrap_load_balancer ? 1 : 0

  name        = "${var.prefix}-nlb-sg"
  description = "Security group for dbx-proxy NLB"
  vpc_id      = var.vpc_id

  # Outbound from NLB on any listener port
  dynamic "egress" {
    for_each = { for l in var.dbx_proxy_listener : l.name => l }
    content {
      description = "Databricks to NLB to dbx-proxy listener ${egress.key}"
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = "tcp"
      cidr_blocks = var.subnet_cidrs
    }
  }

  # Health check port
  egress {
    description = "Databricks to NLB to dbx-proxy health check"
    from_port   = var.dbx_proxy_health_port
    to_port     = var.dbx_proxy_health_port
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
  }

  # We can not lock down ingress to individual sources since we don't know the
  # source IP addresses or Security Group IDs the traffic is originating from.
  # Therefore, we allow all ingress traffic on the SG level. Ingress is controlled
  # by the endpoint service allowed_principals and manual acceptance.

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-nlb-sg"
    },
  )
}

resource "aws_vpc_security_group_egress_rule" "this" {
  count = var.bootstrap_load_balancer ? 0 : length(local.nlb_sg_egress_rules)

  security_group_id = local.nlb_sg_egress_rules[count.index].security_group_id
  from_port         = local.nlb_sg_egress_rules[count.index].port
  to_port           = local.nlb_sg_egress_rules[count.index].port
  ip_protocol       = "tcp"
  cidr_ipv4         = local.nlb_sg_egress_rules[count.index].cidr
  description       = local.nlb_sg_egress_rules[count.index].description
}

resource "aws_lb_target_group" "health" {
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
  load_balancer_arn = local.nlb_arn
  port              = var.dbx_proxy_health_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.health.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-l-health"
    },
  )
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

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-l-${each.key}"
    },
  )
}
