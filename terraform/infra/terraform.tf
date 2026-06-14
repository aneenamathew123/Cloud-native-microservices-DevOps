terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
   backend "s3" {
    bucket         = "opentelemetry-demo-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraformstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


  