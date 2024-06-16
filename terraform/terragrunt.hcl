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
    bucket                = "tf-remote-state20240609191010533500000002"
    dynamodb_table        = "tf-remote-state-lock"
    kms_key_id            = "alias/tf-remote-state-key"
  }
}
