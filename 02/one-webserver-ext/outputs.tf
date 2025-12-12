# [출력 변수]
output "public_ip" {
  value       = aws_instance.myinstance.public_ip
  description = "The public IP address of the web server"
}