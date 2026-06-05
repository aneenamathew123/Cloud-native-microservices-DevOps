output "s3_bucket_name" {
    value = aws_s3_bucket.tfstate.id
    description = "The name of the S3 bucket"
}

output "aws_dynamodb_table" {
    value = aws_dynamodb_table.tfstate-locks.id
    description = "name of the Dynamodb table"
  
}