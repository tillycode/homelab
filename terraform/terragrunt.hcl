dependency "bootstrap" {
  config_path = "${get_repo_root()}/terraform/bootstrap"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    disable_bucket_update = true
    region                = "ap-east-1"
    key                   = "homelab/${path_relative_to_include()}/terraform.tfstate"
    encrypt               = true
    bucket                = dependency.bootstrap.outputs.state_bucket
    dynamodb_table        = dependency.bootstrap.outputs.dynamodb_table
    kms_key_id            = dependency.bootstrap.outputs.kms_key
  }
}

locals {
  aws_default_region    = "ap-southeast-1"
  aliyun_default_region = "ch-hangzhou"
}
