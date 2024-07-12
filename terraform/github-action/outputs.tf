output "github_ssh_public_key" {
  description = "The public key of the SSH key pair for GitHub Actions."
  value       = tls_private_key.github.public_key_openssh
}

output "aws_sops_key_arn" {
  description = "The ARN of the KMS key for SOPS secrets."
  value       = module.kms.aliases[var.aws_sops_key_alias].arn
}
