resource "aws_internet_gateway" "gw" {
 vpc_id = vars.vpc_id
 
 tags = {
   Name = vars.name
 }
}

resource "aws_route_table" "second_rt" {
 vpc_id = vars.vpc_id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table"
 }
}