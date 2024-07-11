locals {
  bootstrap = jsondecode(sops_decrypt_file("${get_repo_root()}/secrets/terraform/tofu-encryption.json")).bootstrap
}

terraform {
  extra_arguments "tf_encryption" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "refresh",
      "show",
      "state",
      "output"
    ]
    env_vars = {
      TF_ENCRYPTION = <<-EOT
        key_provider "pbkdf2" "${local.bootstrap.key_provider_name}" {
          passphrase = "${local.bootstrap.key_provider_passphrase}"
        }
        method "aes_gcm" "new_method" {
          keys = key_provider.pbkdf2.${local.bootstrap.key_provider_name}
        }
        state {
          method = method.aes_gcm.new_method
        }
        plan {
          method = method.aes_gcm.new_method
        }
      EOT
    }
  }
}

inputs = {
  aws_terraform_region          = "ap-east-1"
  aws_terraform_iam_policy_name = "terraform-access"
  output_file                   = "${get_repo_root()}/generated/terraform-bootstrap.json"
}
