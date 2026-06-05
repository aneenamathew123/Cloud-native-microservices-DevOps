## generate code for remote backend
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tfstate"{
  bucket = "opentelemetry-demo-tfstate"
  force_destroy = false

  tags = {
    Name = "opentelemetry-demo-tfstate"
  }
}


resource "aws_s3_bucket_versioning" "tfstate"{
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate"{
  depends_on = [aws_s3_bucket_versioning.tfstate]
  bucket = aws_s3_bucket.tfstate.id
  rule {
    id = "clean_up_old_tfstate_files"
    status = "Enabled"

  filter {}
  
  noncurrent_version_expiration {
    noncurrent_days = 90
  }
  }


}

resource "aws_dynamodb_table" "tfstate-locks"{
  name           = "terraformstate-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  

  attribute {
    name = "LockID"
    type = "S"
  }
   tags = {
    Name = "terraformstate-lock"
  }


}
