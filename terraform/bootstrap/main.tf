terraform {
  encryption {
    state {
      enforced = true
    }
    plan {
      enforced = true
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "ap-east-1"
  region = "ap-east-1"
}

## -----------------------------------------------------------------------------
## REMOTE STATE BACKEND
## ap-east-1 is the primary region, and ap-southeast-1 is the replica region.
## -----------------------------------------------------------------------------

module "remote_state" {
  source             = "nozaq/remote-state-s3-backend/aws"
  enable_replication = false # for lower cost

  providers = {
    aws         = aws.ap-east-1
    aws.replica = aws
  }
}

## -----------------------------------------------------------------------------
## GRANT ACCESS TO GITHUB ACTIONS
## This enables GitHub Actions to assume the OIDC role.
## -----------------------------------------------------------------------------

module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true

  repositories              = ["sunziping2016/homelab"]
  oidc_role_attach_policies = [module.remote_state.terraform_iam_policy.arn]
}

## -----------------------------------------------------------------------------
## SOPS encryption key
## -----------------------------------------------------------------------------

module "kms" {
  source = "terraform-aws-modules/kms/aws"

  description = "The key used to encrypt the SOPS secrets."
  key_usage   = "ENCRYPT_DECRYPT"
  key_users   = [module.github-oidc.oidc_role]
  aliases     = ["sops-key"]

  tags = {
    Terraform = "true"
  }
}
