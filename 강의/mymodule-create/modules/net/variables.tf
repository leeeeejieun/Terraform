variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "my_vpc"
}

variable "igw_name" {
  description = "The name of the Internet Gateway"
  type        = string
  default     = "myIGW"
}

variable "subnet_name" {
  description = "The name of the Public Subnet"
  type        = string
  default     = "myPubSN"
}

variable "rt_name" {
  description = "The name of the Route Table"
  type        = string
  default     = "myPubSN-RT"
}
