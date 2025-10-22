data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    
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
        Name = var.name
    }
}

resource "aws_subnet" "private_subnets" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = false
    
    tags = {
        Name = var.name
    }
}