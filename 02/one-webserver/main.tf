##############################################
# 1. provider 설정
# 2. EC2 Instance 생성(user_data(WEB:8080))
# * SG: Inbound(8080), Outbound(All)
##############################################

# 1. provider 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# 2. 보안 그룹 생성
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow TCP 8080 inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_8080"
  }
}

# 인바운드 규칙 추가
resource "aws_vpc_security_group_ingress_rule" "allow_8080_http" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

# 아웃바운드 규칙 추가 
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # 모든 프로토콜 허용
}

# 3. 웹 서버 인스턴스 생성
resource "aws_instance" "myinstance" {
  ami           = "ami-0f5fcdfbd140e4ab7"
  instance_type = "t3.micro"

  # 보안 그룹 연결
  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  # 사용자 데이터 스크립트
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF

  # user_data 내용이 변경될 때 인스턴스 재생성
  user_data_replace_on_change = true

  tags = {
    Name = "My-First-Instance"
  }
}

