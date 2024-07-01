## -----------------------------------------------------------------------------
## GRANT REMOTE STATE ACCESS TO GITHUB ACTIONS
## -----------------------------------------------------------------------------
data "aws_iam_policy" "terraform" {
  name = var.aws_terraform_iam_policy_name
}

module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true

  repositories              = ["${var.github_repository_owner}/${var.github_repository_name}"]
  oidc_role_attach_policies = [data.aws_iam_policy.terraform.arn]

  tags = {
    Terraform = "true"
  }
}

## -----------------------------------------------------------------------------
## GRANT IN-REPO SECRET ACCESS TO GITHUB ACTIONS
## -----------------------------------------------------------------------------
module "kms" {
  source = "terraform-aws-modules/kms/aws"

  description = "The key used to encrypt the SOPS secrets."
  key_usage   = "ENCRYPT_DECRYPT"
  key_users   = [module.github-oidc.oidc_role]
  aliases     = [var.aws_sops_key_alias]

  tags = {
    Terraform = "true"
  }
}

## -----------------------------------------------------------------------------
## GRANT ACCESS TO ALIYUN
## -----------------------------------------------------------------------------A
resource "alicloud_ims_oidc_provider" "github" {
  issuer_url          = "https://token.actions.githubusercontent.com"
  fingerprints        = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
  issuance_limit_time = "12"
  oidc_provider_name  = "GitHub"
  client_ids          = ["sts.aliyuncs.com"]
}

# FIXME: The provider didn't expose Arn for the oidc provider.
#  I fired an issue for it aliyun/terraform-provider-alicloud#7375.
data "alicloud_account" "current" {
}


locals {
  alicloud_ims_oidc_provider_arn = "acs:ram::${data.alicloud_account.current.id}:oidc-provider/${alicloud_ims_oidc_provider.github.oidc_provider_name}"
}

data "alicloud_ram_policy_document" "assume_role" {
  version = "1"
  statement {
    effect = "Allow"
    action = ["sts:AssumeRole"]

    principal {
      entity      = "Federated"
      identifiers = [local.alicloud_ims_oidc_provider_arn]
    }

    condition {
      operator = "StringEquals"
      variable = "oidc:aud"
      values   = ["sts.aliyuncs.com"]
    }

    condition {
      operator = "StringEquals"
      variable = "oidc:iss"
      values   = [alicloud_ims_oidc_provider.github.issuer_url]
    }

    condition {
      operator = "StringLike"
      variable = "oidc:sub"
      values   = ["repo:${var.github_repository_owner}/${var.github_repository_name}:*"]
    }
  }
}

resource "alicloud_ram_role" "github" {
  name        = "github-oidc-provider-aliyun"
  description = "Role assumed by the GitHub OIDC provider."
  document    = data.alicloud_ram_policy_document.assume_role.document
}

data "alicloud_ram_policy_document" "github" {
  version = "1"
  statement {
    effect = "Allow"
    action = [
      "ecs:Describe*",
      "ecs:List*",
      "vpc:Describe*",
      "vpc:Get*",
    ]
    resource = ["*"]
  }
}

resource "alicloud_ram_policy" "github" {
  policy_name     = "github-oidc-provider-aliyun"
  policy_document = data.alicloud_ram_policy_document.github.document
  description     = "Policy for the GitHub OIDC provider."
}

resource "alicloud_ram_role_policy_attachment" "github_policy" {
  policy_name = alicloud_ram_policy.github.policy_name
  policy_type = "Custom"
  role_name   = alicloud_ram_role.github.name
}

## -----------------------------------------------------------------------------
## SSH KEY
## -----------------------------------------------------------------------------
resource "tls_private_key" "github" {
  algorithm = "ED25519"
}

## -----------------------------------------------------------------------------
## GITHUB REPOSITORY
## import this resource by running the following command:
##     aws-vault exec admin -- terragrunt import github_repository.this $name
## -----------------------------------------------------------------------------
resource "github_repository" "this" {
  name                   = var.github_repository_name
  delete_branch_on_merge = true
  has_downloads          = true
  has_issues             = true
  has_projects           = true
  has_wiki               = true
}

data "github_user" "current" {
  username = var.github_repository_owner
}

resource "github_repository_environment" "prod" {
  environment = "prod"
  repository  = github_repository.this.name
  reviewers {
    users = [data.github_user.current.id]
  }
}
resource "github_actions_variable" "aws_role_to_asume" {
  repository    = github_repository.this.name
  variable_name = "AWS_ROLE_TO_ASSUME"
  value         = module.github-oidc.oidc_role
}

resource "github_actions_variable" "aliyun_role_to_assume" {
  repository    = github_repository.this.name
  variable_name = "ALIYUN_ROLE_TO_ASSUME"
  value         = alicloud_ram_role.github.arn
}

resource "github_actions_variable" "aliyun_oidc_provider_arn" {
  repository    = github_repository.this.name
  variable_name = "ALIYUN_OIDC_PROVIDER_ARN"
  value         = local.alicloud_ims_oidc_provider_arn
}

resource "github_actions_secret" "ssh_private_key" {
  repository      = github_repository.this.name
  secret_name     = "SSH_PRIVATE_KEY"
  plaintext_value = tls_private_key.github.private_key_openssh
}
