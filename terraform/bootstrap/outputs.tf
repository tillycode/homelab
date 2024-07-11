output "kms_key" {
  description = "The KMS customer master key to encrypt state buckets."
  value       = module.remote_state.kms_key_alias.name
}

output "state_bucket" {
  description = "The S3 bucket to store the remote state file."
  value       = module.remote_state.state_bucket.bucket
}

output "dynamodb_table" {
  description = "The DynamoDB table to store the remote state lock."
  value       = module.remote_state.dynamodb_table.id
}

resource "local_file" "backend" {
  filename = var.output_file
  content = jsonencode({
    region          = var.aws_terraform_region,
    state_bucket    = module.remote_state.state_bucket.bucket,
    dynamodb_table  = module.remote_state.dynamodb_table.id,
    kms_key         = module.remote_state.kms_key_alias.name,
    iam_policy_name = var.aws_terraform_iam_policy_name,
  })
}
