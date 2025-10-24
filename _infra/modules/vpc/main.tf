data "aws_availability_zones" "available" {}

locals {
  prefix = "${var.name}-${var.environment}"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = "${local.prefix}-vpc"
    }

    lifecycle {
        prevent_destroy = false
    }
}

resource "aws_subnet" "public_subnets" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
    availability_zone = data.aws_availability_zones.available.names[count.index]

    map_public_ip_on_launch = true
 
    tags = {
        Name = "${local.prefix}-public-subnet"
    }
}

resource "aws_subnet" "private_subnets" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    
    tags = {
        Name = "${local.prefix}-private-subnet"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
 
    tags = {
        Name = "${local.prefix}-gw"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main.id
 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

// public subnet become public by associating with route table having internet gateway route
resource "aws_route_table_association" "route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# our orleans should have restricted access to Internet and AWS services
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets
  depends_on    = [aws_internet_gateway.gw]
  tags = { Name = "${local.prefix}-nat" }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.prefix}-private-rt" }
}

resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assocs" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}