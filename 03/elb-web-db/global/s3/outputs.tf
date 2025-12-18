output "s3_bucket_arn" {
  value = aws_dynamodb_table.mylocktable.arn
}

output "dynamo_table_name" {
  value = aws_dynamodb_table.mylocktable.name
}