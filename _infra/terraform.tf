terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "aws-infrastructure"

    workspaces {
      name = "aws-orleans"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}