data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"

  tags = {
    Name = "myEC2"
  }
}