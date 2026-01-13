# Security group for dbx-proxy instances
resource "aws_security_group" "this" {
  name        = "${local.prefix}-sg"
  description = "Security group for dbx-proxy instances"
  vpc_id      = local.vpc_id

  # Inbound from NLB on any listener port
  dynamic "ingress" {
    for_each = { for l in var.dbx_proxy_listener : l.name => l }
    content {
      description = "Databricks to NLB to dbx-proxy listener ${ingress.key}"
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [for s in data.aws_subnet.this : s.cidr_block]
    }
  }

  # Health check port
  ingress {
    description = "NLB to dbx-proxy health checks"
    from_port   = var.dbx_proxy_health_port
    to_port     = var.dbx_proxy_health_port
    protocol    = "tcp"
    cidr_blocks = [for s in data.aws_subnet.this : s.cidr_block]
  }

  # Allow all egress; alternatively add an egress rule for each target of each listener
  egress {
    description = "Allow all egress for dbx-proxy instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.prefix}-sg"
    },
  )
}

# IAM role for EC2 instances (simplified, extend as needed)
resource "aws_iam_role" "this" {
  name               = "${local.prefix}-ir"
  assume_role_policy = data.aws_iam_policy_document.this.json

  tags = local.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.prefix}-ip"
  role = aws_iam_role.this.name
}

# Launch template for dbx-proxy instances
resource "aws_launch_template" "this" {
  name_prefix   = "${local.prefix}-lt"
  image_id      = "ami-015f3aa67b494b27e"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.this.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  # Cloud-init user data that writes config/compose and bootstraps Docker + docker-compose
  user_data = data.cloudinit_config.this.rendered

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      {
        Name = "${local.prefix}-ec2"
      },
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.tags,
      {
        Name = "${local.prefix}-vol"
      },
    )
  }

  tags = local.tags
}

# Auto Scaling Group for dbx-proxy instances
resource "aws_autoscaling_group" "this" {
  name                      = "${local.prefix}-asg"
  vpc_zone_identifier       = local.subnet_ids
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 1
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }
}

# Attach ASG instances to the NLB target groups
resource "aws_autoscaling_attachment" "this" {
  for_each = aws_lb_target_group.this

  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = each.value.arn
}

# Attach ASG instances to the dbx-proxy-agent target group
resource "aws_autoscaling_attachment" "agent" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.agent.arn
}
