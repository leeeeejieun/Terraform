#######################################
# 1. provider 설정
# 2. EC2
#######################################

# 1. provider 설정
provider "aws" {
  region = "us-east-2"
}

# 2. EC2
# * AMI ID 자동 선택하도록 data source 사용 
#  - Amazon Linux 2023 ami
#  - AMI 카탈로그 > AMI ID 검색 후 세부 정보 확인
data "aws_ami" "amazon2023" {
  most_recent = true # 최신 AMI 선택

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"] # 날짜가 변경될 수 있으므로 * 기호로 표시
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_instance" "myInstance" {
  ami           = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"

  tags = {
    Name = "myInstance"
  }
}

output "ami_id" {
  description = "AMI ID"
  value       = aws_instance.myInstance.ami
}