variable "aws_terraform_region" {
  description = "The AWS region to create the S3 bucket and DynamoDB table in."
  type        = string
}

variable "aws_terraform_iam_policy_name" {
  description = "The name of the IAM policy to attach to the Terraform user."
  type        = string
}

variable "output_file" {
  description = "The file to write the backend configuration to."
  type        = string
}
