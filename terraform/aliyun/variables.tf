variable "project_root" {
  type = string
}

variable "known_hosts_output_file" {
  type = string
}

variable "sops_config_output_file" {
  type = string
}

variable "github_action_ssh_public_key" {
  type = string
}

variable "github_action_sops_key_arn" {
  type = string
}
