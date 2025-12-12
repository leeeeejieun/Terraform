# [입력 변수]
variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "allow_8080"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}