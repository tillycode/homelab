include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  github_admin           = "sunziping2016"
  github_organization    = "tillycode"
  github_repository_name = "homelab"

  aws_default_region            = "ap-southeast-1"
  aws_terraform_iam_policy_name = "terraform-access"

  aliyun_default_region = "cn-hangzhou"
}
