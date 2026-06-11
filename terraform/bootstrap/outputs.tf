output "s3_bucket_name" {
    value = aws_s3_bucket.tfstate.id
    description = "The name of the S3 bucket"
}

output "aws_dynamodb_table" {
    value = aws_dynamodb_table.tfstate_locks.id
    description = "name of the Dynamodb table"
  
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
  description = "ARN of the IAM role for github actions"
}