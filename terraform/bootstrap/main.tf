## generate code for remote backend
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

resource "aws_dynamodb_table" "tfstate_locks"{
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
##Github's OIDC token issuer.

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
  "6938fd4d98bab03faadb97b34396831e3780aea1",
  "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
]

}

resource "aws_iam_role" "github_actions_plan_role" {
  name = "github-actions-plan-role"
  assume_role_policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "Federated": aws_iam_openid_connect_provider.github_oidc.arn
            },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
      "StringEquals": {
         "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         "token.actions.githubusercontent.com:sub": "repo:aneenamathew123/Cloud-native-microservices-DevOps:pull_request"
          }
        }
    }
    ]
  
})

}

resource "aws_iam_role" "github_actions_apply_role" {
  name = "github-actions-apply-role"
  assume_role_policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "Federated": aws_iam_openid_connect_provider.github_oidc.arn
            },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
      "StringEquals": {
         "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         "token.actions.githubusercontent.com:sub": "repo:aneenamathew123/Cloud-native-microservices-DevOps:ref:refs/heads/main"
                }
            }
        }
    ]
})

}

resource "aws_iam_role" "github_actions_platform_role" {
  name = "github-actions-platform-role"
  assume_role_policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "Federated": aws_iam_openid_connect_provider.github_oidc.arn
            },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
      "StringEquals": {
         "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         "token.actions.githubusercontent.com:sub": "repo:aneenamathew123/Cloud-native-microservices-DevOps:ref:refs/heads/main"
                }
            }
        }
    ]
})

}

resource "aws_iam_policy" "github_actions_apply_policy" {
  name = "github-actions-apply-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",           
          "eks:*",                      
          "logs:*",          
          "autoscaling:*",   

          
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"

        ]
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*",
        ]
      }, 
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.tfstate_locks.arn      
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole","iam:CreateRole","iam:DeleteRole",
          "iam:AttachRolePolicy","iam:DetachRolePolicy",
          "iam:PutRolePolicy","iam:DeleteRolePolicy",
          "iam:GetRole","iam:ListAttachedRolePolicies","iam:ListRolePolicies",
        ]
        Resource = "arn:aws:iam::*:role/opentelemetry-*"
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_plan_policy" {
  name = "github-actions-plan-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ec2:Describe*",
          "eks:Describe*",
          "eks:List*",
          "autoscaling:Describe*",
          "logs:Describe*",
          "iam:GetRole",
          "iam:List*",
          "iam:GetPolicy"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]

        Resource = aws_dynamodb_table.tfstate_locks.arn
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_platform_policy" {
  name = "github_actions_platform_policy"
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        "Effect": "Allow",
       "Action": [
         "eks:DescribeCluster",
         "eks:ListClusters"
     ]
       "Resource": "*"
     }, 

      {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/opentelemetry-*"
    },
     {
      "Effect" = "Allow"
       Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
       ]
         Resource = [
          aws_s3_bucket.tfstate.arn,
         "${aws_s3_bucket.tfstate.arn}/*"
      ]
    },

     {
      "Effect" = "Allow"
       Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
       ]
       Resource = aws_dynamodb_table.tfstate_locks.arn
     }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "github_actions_apply_policy_attachment" {
  role       = aws_iam_role.github_actions_apply_role.name
  policy_arn = aws_iam_policy.github_actions_apply_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_plan_policy_attachment" {
  role       = aws_iam_role.github_actions_plan_role.name
  policy_arn = aws_iam_policy.github_actions_plan_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_platform_policy_attachment" {
  role       = aws_iam_role.github_actions_platform_role.name
  policy_arn = aws_iam_policy.github_actions_platform_policy.arn
}

