variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}

variable "subnet_id" {
  description = "The Subnet ID where the EC2 instance will be created"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "mykeypair"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "~/.ssh/mykeypair.pub"
}

variable "sg_name" {
  description = "The name of the Security Group"
  type        = string
  default     = "my_SG"
}

variable "instance_name" {
  description = "The name of the EC2 instance"
  type        = string
  default     = "my_EC2"
}
