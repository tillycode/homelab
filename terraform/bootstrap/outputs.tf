output "kms_key" {
  description = "The KMS customer master key to encrypt state buckets."
  value       = module.remote_state.kms_key_alias.arn
}

output "state_bucket" {
  description = "The S3 bucket to store the remote state file."
  value       = module.remote_state.state_bucket.bucket
}

output "dynamodb_table" {
  description = "The DynamoDB table to store the remote state lock."
  value       = module.remote_state.dynamodb_table.id
}

output "sops_key" {
  description = "The KMS key to encrypt SOPS secrets."
  value       = module.kms.aliases["sops-key"].arn
}
