resource "aws_vpc" "this" {
  count = var.bootstrap_networking ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-vpc"
    },
  )
}

resource "aws_subnet" "this" {
  count = var.bootstrap_networking ? length(var.subnet_cidrs) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.this.names[count.index % length(data.aws_availability_zones.this.names)]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-sn-${data.aws_availability_zones.this.names[count.index % length(data.aws_availability_zones.this.names)]}"
    },
  )
}

# Public subnet used by the NAT gateway
resource "aws_subnet" "public" {
  count = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.nat_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.this.names[0]

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-sn-public-${data.aws_availability_zones.this.names[0]}"
    },
  )
}

# Route tables for subnets
resource "aws_route_table" "private" {
  count = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-rt-private"
    },
  )
}

resource "aws_route_table" "public" {
  count = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-rt-public"
    },
  )
}

resource "aws_route_table_association" "public" {
  count = var.bootstrap_networking && var.enable_nat_gateway ? 1 : 0

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}



resource "aws_route_table_association" "private" {
  count = var.bootstrap_networking && var.enable_nat_gateway ? length(aws_subnet.this) : 0

  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.private[0].id
}
