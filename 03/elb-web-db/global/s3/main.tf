#############################################  
# 1. Provider 설정
# 2. S3 mybucket 생성
#############################################

# 1. Provider 설정
provider "aws" {
  region = "us-east-2"
}

# 2. S3 mybucket 생성
resource "aws_s3_bucket" "mybucket" {
  bucket = "mylje-1109"

  tags = {
    Name = "mybucket"
  }
}

