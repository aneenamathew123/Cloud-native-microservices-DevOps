output "s3_bucket_name" {
    value = aws_s3_bucket.tfstate.id
    description = "The name of the S3 bucket"
}

output "aws_dynamodb_table" {
    value = aws_dynamodb_table.tfstate_locks.id
    description = "name of the Dynamodb table"
  
}

output "github_actions_apply_role_arn" {
  value = aws_iam_role.github_actions_apply_role.arn
  description = "ARN of the infrastructure in aws"
}

output "github_actions_platform_role_arn" {
  value = aws_iam_role.github_actions_platform_role.arn
  description = "ARN of the platform layer in aws"
}