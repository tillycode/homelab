include "root" {
  path = find_in_parent_folders()
}

inputs = {
  github_repository_owner = "sunziping2016"
  github_repository_name  = "homelab"

  aws_default_region            = "ap-southeast-1"
  aws_terraform_iam_policy_name = "terraform-access"

  aliyun_default_region = "cn-hangzhou"
}
