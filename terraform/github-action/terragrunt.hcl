include "root" {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  github_repository_owner = "sunziping2016"
  github_repository_name  = "homelab"

  aws_terraform_region         = include.root.locals.aws_default_region
  aws_terraform_iam_policy_arn = dependency.bootstrap.outputs.terraform_iam_policy
}
