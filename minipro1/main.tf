########################################
# 1. 인프라 구성
# * VPC 생성
# * IGW 생성 및 연결
# * Public Subnet 생성
# * Routing Table 생성 및 연결  
# 2. EC2 생성
# * Security Group 생성
# * Keypair 생성
# * EC2 생성
#   - User_Data(docker CMD)
# 3. 사용자 연결
########################################

########################################
# * VPC 생성
# * DNS hostname 활성화
########################################
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true # DNS 호스트 이름 활성화

  tags = {
    Name = "myVPC"
  }
}

########################################
# * IGW 생성 및 연결
########################################
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

########################################
# * Public Subnet 생성
# * 공인 IP 할당
########################################
resource "aws_subnet" "myPubSN" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # 공인 IP 할당 활성화

  tags = {
    Name = "myPubSN"
  }
}

########################################
# * Routing Table 생성 및 연결  
# * default route -> myIGW
# * myPubSN에 연결
########################################
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  # default route -> myIGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.myPubSN.id # myPubSN에 연결
  route_table_id = aws_route_table.myPubRT.id
}

###############################################################
# * Security Group 생성
# * 개발자가 어떤 서비스를 사용할 지 모르니 모든 트래픽 허용
###############################################################
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow TLS inbound and outbound all traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG_in_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "mySG_out_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

############################################################
# * Keypair 생성
# * 선수 작업 : ssh-ketgen -t rsa -N "" -f ~/.ssh/mykeypair 
#############################################################
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

##################################################
# * EC2 생성
# * 새로 생성한 public subnet(myPubSN)에 EC2 생성
# * security group(mySG) 저장
# - ami : Ubuntu 24.04 LTS
# - User_Data(docker 설치)
##################################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "myEC2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.myPubSN.id           # myPubSN에 배치
  vpc_security_group_ids = [aws_security_group.mySG.id]    # 보안그룹 연결
  key_name               = aws_key_pair.mykeypair.key_name # 키페어 지정

  user_data_replace_on_change = true
  user_data_base64            = filebase64("./user_data.sh")

  # 인스턴스가 생성된 후에 수행되는 작업
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  provisioner "local-exec" {
    # make_config.sh 파일을 동적으로 변경
    command = templatefile("make_config.sh", {
      hostname = self.public_ip,
      user = "ubuntu", 
      identifyfile = "~/.ssh/mykeypair"
    })
    interpreter = ["bash", "-c"]   # bash 쉘로 실행
  }

  tags = {
    Name = "myEC2"
  }
}

########################################
# 3. 사용자 연결
########################################
