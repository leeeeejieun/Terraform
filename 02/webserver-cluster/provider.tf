terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}