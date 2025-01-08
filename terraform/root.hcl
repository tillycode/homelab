locals {
  bootstrap = jsondecode(file("${get_repo_root()}/generated/terraform-bootstrap.json"))
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    disable_bucket_update = true
    region                = local.bootstrap.region
    key                   = "homelab/${path_relative_to_include()}/terraform.tfstate"
    encrypt               = true
    bucket                = local.bootstrap.state_bucket
    dynamodb_table        = local.bootstrap.dynamodb_table
    kms_key_id            = local.bootstrap.kms_key
  }
}

dependencies {
  paths = ["${path_relative_from_include()}/bootstrap"]
}
