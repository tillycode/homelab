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

  repositories              = ["${var.github_organization}/${var.github_repository_name}"]
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
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "alicloud_ims_oidc_provider" "github" {
  issuer_url          = "https://token.actions.githubusercontent.com"
  fingerprints        = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
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
      values   = ["repo:${var.github_organization}/${var.github_repository_name}:*"]
    }
  }

  statement {
    effect = "Allow"
    action = ["sts:AssumeRole"]

    principal {
      entity = "RAM"
      identifiers = [
        "acs:ram::${data.alicloud_account.current.id}:root"
      ]
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
      "ecs:DescribeInstanceAttribute",
      "ecs:DescribeInstanceAutoRenewAttribute",
      "ecs:DescribeInstanceMaintenanceAttributes",
      "ecs:DescribeInstanceRamRole",
      "ecs:DescribeInstances",
      "ecs:DescribeKeyPairs",
      "ecs:DescribeNetworkInterfaces",
      "ecs:DescribeSecurityGroupAttribute",
      "ecs:DescribeSecurityGroups",
      "ecs:DescribeUserData",
      "ecs:ListTagResources",
      "vpc:DescribeEipAddresses",
      "vpc:DescribeNatGateways",
      "vpc:DescribeRouteTableList",
      "vpc:DescribeRouteTables",
      "vpc:DescribeVpcAttribute",
      "vpc:DescribeVSwitchAttributes",
      "vpc:ListTagResources",
    ]
    resource = ["*"]
  }
}

resource "alicloud_ram_policy" "github" {
  policy_name     = "github-oidc-provider-aliyun"
  policy_document = data.alicloud_ram_policy_document.github.document
  description     = "Policy for the GitHub OIDC provider."
  rotate_strategy = "DeleteOldestNonDefaultVersionWhenLimitExceeded"
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
  name             = var.github_repository_name
  has_downloads    = true
  has_issues       = true
  has_projects     = true
  has_wiki         = true
  allow_auto_merge = true
  # Small PRs can use squash merging, whereas large PRs should use merge commits.
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}

data "github_user" "admin" {
  username = var.github_admin
}

resource "github_repository_environment" "infrastructure" {
  environment = "infrastructure"
  repository  = github_repository.this.name
  reviewers {
    users = [data.github_user.admin.id]
  }
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "infrastructure" {
  repository     = github_repository.this.name
  environment    = github_repository_environment.infrastructure.environment
  branch_pattern = "master"
}

resource "github_repository_ruleset" "master" {
  enforcement = "active"
  name        = "master"
  repository  = github_repository.this.name
  target      = "branch"
  conditions {
    ref_name {
      exclude = []
      include = [
        "~DEFAULT_BRANCH",
      ]
    }
  }
  rules {
    deletion         = true
    non_fast_forward = true
    pull_request {}
    required_status_checks {
      strict_required_status_checks_policy = true
      required_check {
        context        = "plan"
        integration_id = 15368 # Github Actions
      }
      required_check {
        context        = "build"
        integration_id = 15368 # Github Actions
      }
    }
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
