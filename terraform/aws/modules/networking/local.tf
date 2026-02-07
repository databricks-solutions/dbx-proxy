locals {

  vpc_id       = var.bootstrap_networking ? aws_vpc.this[0].id : var.vpc_id
  subnet_ids   = length(var.subnet_ids) > 0 ? var.subnet_ids : [for s in aws_subnet.this : s.id]
  subnet_cidrs = length(var.subnet_ids) > 0 ? [for s in values(data.aws_subnet.this) : s.cidr_block] : [for s in aws_subnet.this : s.cidr_block]

}
