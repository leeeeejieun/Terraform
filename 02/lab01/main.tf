###################################
# 1. provides 설정
# 2. VPC 생성
# 3. IGW 생성 및 연결
# 4. PubSN 생성
# 5. PubSN-RT 생성 및 연결
###################################
# 1) provider 설정
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

# 2) VPC 생성 및 dns 호스트 이름 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#enable_dns_hostnames-2
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"   # VPC CIDR 블록
  enable_dns_hostnames = true        # DNS 호스트 이름 활성화

  tags = {
    Name = "myVPC"   # VPC 이름 태그
  }
}

# 3) IGW 생성 및 VPC에 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.myVPC.id   # 생성한 VPC에 연결(Output 참조)

  tags = {
    Name = "IGW"  # IGW 이름 태그
  }
}

# 4) myPubSN 생성 및 공인 IP 자동 할당 설정
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id    # myVPC에 생성
  cidr_block = "10.0.1.0/24"       # myPubSN CIDR 블록
  map_public_ip_on_launch = true   # 공인 IP 자동 할당 설정

  tags = {
    Name = "myPubSN"  # Subnet 이름 태그
  }
}

# 5) myPubSN-RT 생성 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "myPubSN-RT" {
  vpc_id = aws_vpc.myVPC.id   # myVPC에 생성

  # 라우팅 테이블 설정
  route {
    cidr_block = "0.0.0.0/0"   # local 트래픽 제외 모든 트래픽
    gateway_id = aws_internet_gateway.IGW.id  # IGW로 라우팅
  }

  tags ={
    Name = "myPubSN-RT"  # 라우팅 테이블 이름 태그
  }
}

# 6) myPubSN-RT와 myPubSN 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPubSN-RT-assoc" {
  subnet_id      = aws_subnet.myPubSN.id   # myPubSN 선택
  route_table_id = aws_route_table.myPubSN-RT.id  # myPubSN-RT 연결
}

