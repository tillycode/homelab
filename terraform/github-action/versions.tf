terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }
  }
}

provider "aws" {
  region = var.aws_default_region
}

provider "alicloud" {
  region = var.aliyun_default_region
}


provider "github" {
  owner = var.github_organization
}
