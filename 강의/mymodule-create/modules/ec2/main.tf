
resource "aws_security_group" "my_SG" {
  name        = var.sg_name
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}

resource "aws_key_pair" "my_keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "my_EC2" {
  ami                         = "ami-00e428798e77d38d9"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.my_SG.id]
  key_name                    = aws_key_pair.my_keypair.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}
