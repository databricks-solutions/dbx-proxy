# Network Load Balancer for Databricks Serverless → dbx-proxy
resource "aws_lb" "this" {
  name               = "${local.prefix}-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = local.tags
}

# One target group per listener port for simple configuration.
resource "aws_lb_target_group" "this" {
  for_each = { for l in var.dbx_proxy_listener : l.name => l }

  name        = "tg-${each.key}"
  port        = each.value.port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = local.vpc_id

  health_check {
    protocol            = upper(each.value.mode)
    port                = var.dbx_proxy_health_port
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = local.tags
}

resource "aws_lb_listener" "this" {
  for_each = aws_lb_target_group.this

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)

  default_action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
}
