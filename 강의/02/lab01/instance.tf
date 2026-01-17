######################################
# 1. SG 생성
# 2. EC2 생성
######################################

# 1) SG 생성
# * ingress: 80/tcp, 443/tcp 허용
# * egress: all 허용
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# 보안그룹 생성
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow TLS inbound 80/tcp, 443/tcp traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id  # VPC 지정

  tags = {
    Name = "mySG"
  }
}

# 인바운드 규칙 추가 - 80/tcp
resource "aws_vpc_security_group_ingress_rule" "mySG_80" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# 인바운드 규칙 추가 - 443/tcp
resource "aws_vpc_security_group_ingress_rule" "mySG_443" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# 아웃바운드 규칙 추가 - all
resource "aws_vpc_security_group_egress_rule" "mySG_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"   # 모든 트래픽 허용
  ip_protocol       = "-1"   # 모든 프로토콜 허용
}

# 2) EC2 생성
# * user_data(web:80,443) -> user_data 변경 시 EC2 재생성 필요
# * security_group: mySG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

# WEB 서버 인스턴스 생성
resource "aws_instance" "myEC2" {
  ami           = "ami-00e428798e77d38d9"    # AMI 이미지 : Amozon linux 2023 ami
  instance_type = "t3.micro"                 # 인스턴스 타입: t3.micro
  subnet_id     = aws_subnet.myPubSN.id      # myPubSN 서브넷에 생성
  vpc_security_group_ids = [aws_security_group.mySG.id]  # mySG 보안 그룹 연결
  
  # user_data 스크립트 
  user_data_replace_on_change = true  # user_data 변경 시 인스턴스 재생성
  user_data = <<-EOF
    #!/bin/bash
    dnf -y install httpd mod_ssl
    echo "My Web Server Test Page" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "myEC2"
  }
}