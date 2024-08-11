variable "boot" {
  type = string
  validation {
    condition     = contains(["UEFI", "BIOS"], var.boot)
    error_message = "Invalid boot type, must be either \"UEFI\" or \"BIOS\"."
  }
}

variable "arch" {
  type    = string
  default = "x86_64"
  validation {
    condition     = contains(["x86_64", "aarch64"], var.arch)
    error_message = "Invalid architecture, must be either \"x86_64\" or \"aarch64\"."
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(["cn", "global"], var.region)
    error_message = "Invalid region, must be either \"cn\" or \"global\"."
  }
}

variable "ssh_host" {
  type    = string
  default = null
}

variable "bastion_host" {
  type    = string
  default = null
}

variable "reinstall_triggers" {
  type    = map(string)
  default = {}
}

variable "public_ipv4" {
  type    = string
  default = null
}

variable "private_ipv4" {
  type    = string
  default = null
}

variable "public_ipv6" {
  type    = string
  default = null
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "disks" {
  type = list(object({
    name = string
    size = number
  }))
}
