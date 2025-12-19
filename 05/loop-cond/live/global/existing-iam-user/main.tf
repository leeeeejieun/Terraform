provider "aws" {
  region = "us-east-2"
}

# 반복문 사용 예시

# resource "aws_iam_user" "createuser" {
#   count = 3      # count.index => 0, 1, 2
#   name = "neo.${count.index}"
# }

resource "aws_iam_user" "createuser" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}

