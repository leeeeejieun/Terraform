output "myalb_dns_name" {
  description = "My ALB DNS Name"
  value = aws_lb.myalb.dns_name
}

output "myalb_url" {
  description = "My ALB URL"
  value       = "http://${aws_lb.myalb.dns_name}"
}