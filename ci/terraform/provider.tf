terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${var.deploy_to_account}:role/7FContinuousDelivery"
  }
}
