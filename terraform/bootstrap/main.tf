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
  source = "nozaq/remote-state-s3-backend/aws"

  providers = {
    aws         = aws.ap-east-1
    aws.replica = aws
  }
}

## -----------------------------------------------------------------------------
## GRANT ACCESS TO THE ADMIN TEAM
## This enables the team members to manage Terraform states on local machines.
## -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

data "aws_identitystore_group" "admin_team" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "Admin team"
    }
  }
}

resource "aws_ssoadmin_permission_set" "terraform_user" {
  name         = "TerraformUser"
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "terraform_user" {
  instance_arn       = aws_ssoadmin_permission_set.terraform_user.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.terraform_user.arn
  customer_managed_policy_reference {
    name = module.remote_state.terraform_iam_policy.name
    path = "/"
  }
}

resource "aws_ssoadmin_account_assignment" "terraform_user_admin_team" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.terraform_user.arn

  principal_id   = data.aws_identitystore_group.admin_team.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
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
