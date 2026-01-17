output "vpc_id" {
  value = module.net.vpc_id
}

output "public_subnet_id" {
  value = module.net.public_subnet_id
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}
