provider "aws" {
  region = "us-east-2"
}

module "net" {
  source = "./modules/net"
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id    = module.net.vpc_id
  subnet_id = module.net.public_subnet_id
}
