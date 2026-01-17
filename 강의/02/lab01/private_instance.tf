###################################################
# 1. 탄력적 IP 생성
# 2. NAT Gateway 생성 -> Public Subnet
# 3. Private Subnet 생성
# 4. Private Routing Table 생성 및 NAT Gateway 연결
# 5. SG 생성
# 6. EC2 생성 
###################################################


# 1) Elastic IP 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "myEIP" {
  domain   = "vpc"

  tags = {
    Name = "myEIP"
  }
}

# 2) NAT Gateway 생성 -> Public Subnet
# * Elastic IP 생성된 상태에서 작업
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }

  depends_on = [aws_internet_gateway.IGW]  # IGW 생성 후 NAT Gateway 생성되도록 명시
}

# 3) Private Subnet 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id  # myVPC에 생성
  cidr_block = "10.0.2.0/24"          # myPriSN CIDR 블록

  tags = {
    Name = "myPriSN"    # Subnet 이름 태그
  }
}

# 4) Private Routing Table 생성 및 NAT Gateway 연결
# * Private Route Table 생성
# * NAT Gateway를 default route로 설정
# * Private Subnet과 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "myPriSN-RT" {
  vpc_id = aws_vpc.myVPC.id   # myVPC에 생성

  route {
    cidr_block = "0.0.0.0/0"   # local 트래픽 제외 모든 트래픽
    gateway_id = aws_nat_gateway.myNAT-GW.id  # NAT Gateway로 라우팅
  }

  tags = {
    Name = "myPriSN-RT"  # 라우팅 테이블 이름 태그
  }
}

# PriSN-RT와 Private Subnet 연결
resource "aws_route_table_association" "myPriSN-RT-assoc" {
  subnet_id      = aws_subnet.myPriSN.id          # myPriSN 선택
  route_table_id = aws_route_table.myPriSN-RT.id  # myPriSN-RT 연결
}

# 5) SG 생성
# * myEC2-2가 사용할 SG 생성
# - 22/tcp, 80/tcp, 443/tcp 허용
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mySG2" {
  name        = "mySG2"
  description = "Allow TLS inbound  22/tcp, 80/tcp, 443/tcp traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id   # VPC 지정

  tags = {
    Name = "mySG2"
  }
}

# 인바운드 규칙 추가 - 22/tcp
resource "aws_vpc_security_group_ingress_rule" "mySG2-22" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# 인바운드 규칙 추가 - 80/tcp
resource "aws_vpc_security_group_ingress_rule" "mySG2-80" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# 인바운드 규칙 추가 - 443/tcp
resource "aws_vpc_security_group_ingress_rule" "mySG2-443" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# 아웃바운드 규칙 추가 - all
resource "aws_vpc_security_group_egress_rule" "mySG2-all" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"   # 모든 트래픽 허용
  ip_protocol       = "-1"   # 모든 프로토콜 허용
}

# 6) EC2 생성 
# * 키페어 생성 후 EC2 생성 수행
# * mySG2 보안 그룹 연결
# * myPriSN에 생성 설정 - mykeypair
# * user_data(web:80,443) - user_data 변경 시 EC2 재생성 필요

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")  # 로컬 퍼블릭 키 경로
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myEC2-2" {
  ami           = "ami-00e428798e77d38d9"      # AMI 이미지 : Amozon linux 2023 ami
  instance_type = "t3.micro"                   # 인스턴스 타입: t3.micro
  subnet_id   = aws_subnet.myPriSN.id          # myPriSN 서브넷에 생성
  vpc_security_group_ids = [aws_security_group.mySG2.id]    # mySG2 보안 그룹 연결
  key_name = "mykeypair"   # 키페어 설정

  user_data_replace_on_change = true  # user_data 변경 시 인스턴스 재생성
  # user_data 스크립트
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd mod_ssl
    echo "My Private Web Server Test Page" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "myEC2-2"  # 인스턴스 이름 태그
  }
}
