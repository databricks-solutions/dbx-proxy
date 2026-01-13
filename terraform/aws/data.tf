data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_vpc" "this" {
  id = local.vpc_id
}

data "aws_subnet" "this" {
  for_each = toset(local.subnet_ids)
  id       = each.value
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
