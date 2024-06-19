terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1"
    }

  }
}

provider "alicloud" {
  region = "cn-hangzhou"
}

resource "alicloud_ims_oidc_provider" "github" {
  issuer_url          = "https://token.actions.githubusercontent.com"
  fingerprints        = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
  issuance_limit_time = "12"
  oidc_provider_name  = "GitHub"
  client_ids          = ["sts.aliyuncs.com"]
}
