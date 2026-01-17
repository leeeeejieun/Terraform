# 1. VPC 생성 - 10.0.0.0/16
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myVPC"
  }
}

# 2. IGW 생성 및 VPC 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# 3. Public Subnet 3개 생성
# * cidr block 정보
# - 10.0.1.0/24
# - 10.0.2.0/24
# - 10.0.3.0/24

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_azs" {
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

resource "aws_subnet" "myPubSN" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.myVPC.id                # VPC 지정
  availability_zone       = var.public_azs[count.index]     # 가용 영역
  cidr_block              = var.public_subnets[count.index] # CIDR 블록
  map_public_ip_on_launch = true                            # 공인 IP 자동 할당 설정

  tags = {
    Name = "myPubSN-${count.index + 1}" # index가 0부터 시작하므로 +1을 필요
  }
}

# 4. Public Route Table 생성
# * 라우팅 테이블 정보
# - myPubRT1, myPubRT2, myPubRT3
# - IGW 연결 & Public Subnet 3개와 연결

resource "aws_route_table" "myPubSN-RT" {
  count  = length(var.public_subnets) # Public Subnet 개수만큼 생성
  vpc_id = aws_vpc.myVPC.id           # VPC 지정

  # 라우팅 테이블 설정
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubSN-RT${count.index + 1}"
  }
}

# Public Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "myPubSN-RT-assoc" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.myPubSN[count.index].id
  route_table_id = aws_route_table.myPubSN-RT[count.index].id
}

# 5. NAT Gateway 생성
# - Elastic IP 생성
# - NAT Gateway 생성

resource "aws_eip" "myEIP" {
  count  = length(var.public_subnets) # Public Subnet 개수만큼 생성
  domain = "vpc"                      # 탄력적 IP를 VPC 내에서 사용

  tags = {
    Name = "myEIP-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "myNAT-GW" {
  count         = length(var.public_subnets)         # Public Subnet 개수만큼 생성
  allocation_id = aws_eip.myEIP[count.index].id      # EIP 할당 
  subnet_id     = aws_subnet.myPubSN[count.index].id # Public Subnet 연결

  tags = {
    Name = "myNAT-GW-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.myIGW] # IGW 생성 후 NAT Gateway 생성되도록 명시
}

# 6. Private Subnet 3개 생성
# * cidr block 정보
# - 10.0.4.0/24
# - 10.0.5.0/24
# - 10.0.6.0/24

variable "private_subnets" {
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_azs" {
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

resource "aws_subnet" "myPriSN" {
  count = length(var.private_subnets) # Private Subnet 개수만큼 생성

  vpc_id                  = aws_vpc.myVPC.id                 # VPC 지정
  availability_zone       = var.private_azs[count.index]     # 가용 영역
  cidr_block              = var.private_subnets[count.index] # CIDR 블록
  map_public_ip_on_launch = true                             # 공인 IP 자동 할당 설정

  tags = {
    Name = "myPriSN-${count.index + 1}" # index가 0부터 시작하므로 +1을 필요
  }
}

# 7. Private Route Table 생성
# * 라우팅 테이블 정보
# - myPriRT1, myPriRT2, myPriRT3
# - NAT Gateway & Private Subnet 연결

resource "aws_route_table" "myPriSN-RT" {
  count  = length(var.private_subnets) # Private Subnet 개수만큼 생성
  vpc_id = aws_vpc.myVPC.id            # VPC 지정

  # 라우팅 테이블 설정
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.myNAT-GW[count.index].id
  }

  tags = {
    Name = "myPriSN-RT${count.index + 1}"
  }
}

# Private Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "myPriSN-RT-assoc" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.myPriSN[count.index].id
  route_table_id = aws_route_table.myPriSN-RT[count.index].id
}
