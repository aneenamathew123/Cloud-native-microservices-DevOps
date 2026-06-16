terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }

  }
   backend "s3" {
    bucket         = "opentelemetry-demo-tfstate"
    key            = "platform/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraformstate-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "opentelemetry-demo-tfstate"
    key    = "infra/terraform.tfstate"
    region = "eu-central-1"
  }
} 

provider "aws" {
  region = "eu-central-1"
}

provider "kubectl" {
  host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca_certificate)
  load_config_file = false
 exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name",
                   data.terraform_remote_state.infra.outputs.cluster_name]
  }
 
}
                                          
provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.infra.outputs.cluster_name]
      command     = "aws"
    }
  }
}                                                   


