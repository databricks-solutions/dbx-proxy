terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }

    cloudinit = {
      source = "hashicorp/cloudinit"
    }

    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  # authentication configured via env!
  region = var.region

  default_tags {
    tags = local.tags
  }
}
