resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = var.igw_name
  }
}

resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr
  tags = {
    Name = var.subnet_name
  }
}

resource "aws_route_table" "myPubSN-RT" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = var.rt_name
  }
}

resource "aws_route_table_association" "my_pub_sn_assoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubSN-RT.id
}
