variable "github_admin" {
  description = "The admin of the GitHub repository."
  type        = string
}

variable "github_organization" {
  description = "The organization of the GitHub repository."
  type        = string
}

variable "github_repository_name" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "aliyun_default_region" {
  description = "The default AliCloud region to use."
  type        = string
}

variable "aws_default_region" {
  description = "The default AWS region to use."
  type        = string
}

variable "aws_terraform_iam_policy_name" {
  description = "The name of the IAM policy to access the remote state environment."
  type        = string
}

variable "aws_sops_key_alias" {
  description = "The alias of the KMS key to encrypt the SOPS secrets."
  type        = string
  default     = "sops-key"
}
