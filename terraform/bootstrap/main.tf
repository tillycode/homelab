terraform {
  encryption {
    state { enforced = true }
    plan { enforced = true }
  }

  # This module depends on "state encryption" which is a feature introduced in
  # OpenTofu v1.7.0
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_terraform_region
}

## -----------------------------------------------------------------------------
## REMOTE STATE BACKEND
## -----------------------------------------------------------------------------

module "remote_state" {
  source             = "nozaq/remote-state-s3-backend/aws"
  enable_replication = false # for lower cost

  override_terraform_iam_policy_name = true
  terraform_iam_policy_name          = var.aws_terraform_iam_policy_name

  providers = {
    aws = aws
    # actually this won't be used by the module, because replication is disabled
    aws.replica = aws
  }
}
