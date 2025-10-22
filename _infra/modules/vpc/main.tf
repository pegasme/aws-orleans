data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = var.name
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
        Name = "${var.name}-public"
    }
}

resource "aws_subnet" "private_subnets" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    
    tags = {
        Name = "${var.name}-private"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
 
    tags = {
        Name = var.name
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main.id
 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    } 

    tags = {
        Name = var.name
    }
}

// public subnet become public by associating with route table having internet gateway route
resource "aws_route_table_association" "route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.name}-nat-gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = toset([aws_subnet.private_subnets[*].id])
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}