####################################
# 0. Infra
# 1. ALB
# * SG 생성
# * TG 생성
# * ALB 생성
# * ALB Listener 생성
# * ALB Listener Rule 생성
# 2. ASG
# * SG 생성
# * Launch Template 생성
# * ASG 생성
####################################

# 0. Infra
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "default" {
  default = true # 기본 VPC 사용
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

####################################
# 1. ALB
####################################
# * SG 생성
# 80/tcp 허용
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "myalb_sg" {
  name        = "myalb_sg"
  description = "Allow TLS inbound 80 traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myalb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myalb_allow_80" {
  security_group_id = aws_security_group.myalb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_port
  to_port           = var.web_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "myalb_allow_all" {
  security_group_id = aws_security_group.myalb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# * TG 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "myalb_tg" {
  name     = "myalb-tg"
  port     =  var.web_port
  protocol = "HTTP"
  vpc_id   = data.aws_subnets.default.id
}

# * ALB 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myalb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "myalb"
  }
}

# * ALB Listener 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "myalb_listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = var.web_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb_tg.arn
  }
}

# * ALB Listener Rule 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
resource "aws_lb_listener_rule" "myalb_listener_rule" {
  listener_arn = aws_lb_listener.myalb_listener.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb_tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

####################################
# 2. ASG
####################################
# * SG 생성
resource "aws_security_group" "asg_sg" {
  name        = "asg_sg"
  description = "Allow TLS inbound 80 traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "asg_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myasg_allow_80" {
  security_group_id = aws_security_group.asg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_port
  to_port           = var.web_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "my_asg_allow_all" {
  security_group_id = aws_security_group.asg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# * Launch Template 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
data "aws_ami" "amazon2023" {
  most_recent = true
  owners      = [var.aws]

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

resource "aws_launch_template" "mylt" {
  name = "mylt"

  image_id      = data.aws_ami.amazon2023.id
  instance_type = var.vCPU2_MEM1g

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "mylt"
    }
  }

  user_data = filebase64("./user_data.sh")
}

# * ASG 생성
# * target group
# * depends_on
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "myasg" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = var.initEC2num
  min_size            = var.minEC2num
  max_size            = var.maxEC2num

  target_group_arns = [aws_lb_target_group.myalb_tg.arn]
  depends_on        = [aws_lb_target_group.myalb_tg]

  launch_template {
    id      = aws_launch_template.mylt.id
    version = "1.0"
  }
}