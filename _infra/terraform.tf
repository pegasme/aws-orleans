terraform {
  required_version = ">= 1.2.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "PegasTest"

    workspaces {
      name = "aws-orleans"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}