
resource "aws_security_group" "this" {
  name        = "${var.prefix}-sg"
  description = "Security group for dbx-proxy instances"
  vpc_id      = var.vpc_id

  # Inbound from NLB on any listener port
  dynamic "ingress" {
    for_each = { for l in var.dbx_proxy_listener : l.name => l }
    content {
      description = "Databricks to NLB to dbx-proxy listener ${ingress.key}"
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = var.subnet_cidrs
    }
  }

  # Health check port
  ingress {
    description = "Databricks to NLB to dbx-proxy health check"
    from_port   = var.dbx_proxy_health_port
    to_port     = var.dbx_proxy_health_port
    protocol    = "tcp"
    cidr_blocks = var.subnet_cidrs
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
    var.tags,
    {
      Name = "${var.prefix}-sg"
    },
  )
}

# IAM role for EC2 instances (simplified, extend as needed)
resource "aws_iam_role" "this" {
  name               = "${var.prefix}-ir"
  assume_role_policy = data.aws_iam_policy_document.this.json

  tags = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.prefix}-ip"
  role = aws_iam_role.this.name
}

# Launch template for dbx-proxy instances
resource "aws_launch_template" "this" {
  name_prefix   = "${var.prefix}-lt"
  image_id      = data.aws_ssm_parameter.al2023_ami_id.value
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.this.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  # Cloud-init user data that writes config/compose and bootstraps Docker + docker-compose
  user_data = data.cloudinit_config.this.rendered

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.prefix}-ec2"
      },
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.prefix}-vol"
      },
    )
  }

  tags = var.tags
}

# Auto Scaling Group for dbx-proxy instances
resource "aws_autoscaling_group" "this" {
  name                      = "${var.prefix}-asg"
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_capacity
  desired_capacity          = var.max_capacity
  max_size                  = var.max_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.latest_version)
  }

  dynamic "tag" {
    for_each = var.tags
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
      # With desired=max=1, allowing downtime lets the ASG replace the single instance
      # using the latest launch template version.
      min_healthy_percentage = var.max_capacity == 1 ? 0 : 50
    }
  }
}

# Attach ASG instances to the NLB target groups
resource "aws_autoscaling_attachment" "this" {
  for_each = var.nlb_target_group_arns

  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = each.value
}
