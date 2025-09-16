resource "aws_vpc" "vpc" {
    tags = {
        Name = var.name
    }

    lifecycle {
        prevent_destroy = false
    }
}