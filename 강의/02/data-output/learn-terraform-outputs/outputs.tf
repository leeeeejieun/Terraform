# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output declarations
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "elb_url" {
  description = "LB URL"
  value       = "http://${module.elb_http.elb_dns_name}"
}

output "ec2_number" {
  value = length(module.ec2_instances.instance_ids) # 사용자 정의 모듈
}

output "db_username" {
  description = "DB_Admin_ID"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "db_password" {
  description = "DB_Admin_Password"
  value       = aws_db_instance.database.password
  sensitive   = true
}