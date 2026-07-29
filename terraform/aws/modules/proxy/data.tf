data "aws_ec2_instance_type" "this" {
  instance_type = var.instance_type
}

data "aws_ssm_parameter" "al2023_ami_id" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# Look up the supplied AMI so its architecture can be validated against the instance type at plan time.
# Only queried when a custom ami_id is provided; the default SSM (arm64) path skips this.
data "aws_ami" "this" {
  count  = var.ami_id != null ? 1 : 0
  owners = ["self", "amazon", "aws-marketplace"]

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "#cloud-config\n${yamlencode(local.cloud_config)}"
  }
}
