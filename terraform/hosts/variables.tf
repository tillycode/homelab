variable "project_root" {
  type = string
}

variable "hosts" {
  type = map(object({
    boot   = string
    arch   = string
    region = string
    ssh = object({
      host         = string
      bastion_host = optional(string)
    })
    reinstall_triggers = optional(map(string), {})
    addresses = object({
      public_ipv4  = optional(string)
      private_ipv4 = optional(string)
      public_ipv6  = optional(string)
    })
    resources = object({
      cpu    = number
      memory = number
      disks = list(object({
        name = string
        size = number
      }))
    })
  }))
}

variable "known_hosts_output_file" {
  type = string
}

variable "sops_config_output_file" {
  type = string
}

variable "hosts_output_file" {
  type = string
}

variable "github_action_sops_key_arn" {
  type = string
}
