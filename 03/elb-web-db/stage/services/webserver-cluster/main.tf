##############################################
# 1. provider
# * terraform 
# * provider
# * terraform_remote_state
# 2. ASG
# * default SG
# * default subnets
# * launch template
# * TG
# * ASG
# 3. ALB
# * SG
# * ALB 
# * ALB listener
# * ALB lister rule
##############################################

####################################################
# 1. provider
####################################################
# * terraform 
# * provider
# * terraform_remote_state
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "myremotestate" {
  backend = "s3"

  config = {
    bucket         = "mylje-1109"
    key            = "global/s3/terraform.tfstate"  
    region         = "us-east-2"  
    use_lockfile  = true
  }
}

####################################################
# 2. ASG
####################################################
# * default SG
# * default subnets
# * launch template
# * TG
# * ASG

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default Subnetes
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG - LT에 사용할 SG 정의
resource "aws_security_group" "myLTSG" {
  name        = "myLTSG"
  description = "Allow TLS inbound 80/tcp traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myLTSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myLTSG-in-80" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "myLTSG-out-all" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# launch template 
#  - aws_ami_data_source
data "aws_ami" "amazon2023" {
  most_recent      = true
  owners           = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "myLT" {
  name = "myLT"
  image_id = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myLTSG.id]

  user_data = base64encode(templatefile("./user_data.sh", {
    dbaddress = data.terraform_remote_state.myremotestate.outputs.dbaddress,
    dbname  =  data.terraform_remote_state.myremotestate.outputs.dbname,
    dbport =  data.terraform_remote_state.myremotestate.outputs.dbport
  }))
}

# * TG 생성
resource "aws_lb_target_group" "myALGTG" {
  name     = "myALGTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# * ASG 생성
# * target_group_arns
# * depends_on
resource "aws_autoscaling_group" "myASG" {
  name                      = "myASG"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2

  target_group_arns = [aws_lb_target_group.myALGTG.arn]
  depends_on = [aws_lb_target_group.myALGTG]

  health_check_grace_period = 300
  health_check_type         = "ELB"

  force_delete              = true
  vpc_zone_identifier       = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.myLT.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = false
  }
}

####################################################
# 3. ALB
####################################################
# * SG
# * ALB 
# * ALB listener
# * ALB lister rule

# SG - ALB을 위한 SG -> ASG 구성 시 생성한 보안 그룹 재사용
# 80/tcp

# ALB 생성
resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myLTSG.id]
  subnets            = data.aws_subnets.default.ids
}

# ALB listener 정의
resource "aws_lb_listener" "myALB_listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALGTG.arn
  }
}

# ALB listener Rule 
resource "aws_lb_listener_rule" "myALB-listener-rule" {
  listener_arn = aws_lb_listener.myALB_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALGTG.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}



