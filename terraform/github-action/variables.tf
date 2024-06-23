variable "github_repository_owner" {
  description = "The owner of the GitHub repository to create."
  type        = string
}

variable "github_repository_name" {
  description = "The name of the GitHub repository to create."
  type        = string
}

variable "aws_terraform_region" {
  description = "The AWS region to access the remote state environment."
  type        = string
}

variable "aws_terraform_iam_policy_arn" {
  description = "The ARN of the IAM policy to access the remote state environment."
  type        = string
}

variable "aws_sops_key_alias" {
  description = "The alias of the KMS key to encrypt the SOPS secrets."
  type        = string
  default     = "sops-key"
}
