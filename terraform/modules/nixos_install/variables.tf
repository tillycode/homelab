variable "triggers" {
  type = map(string)
}

variable "working_directory" {
  type = string
}

variable "nixos_anywhere_version" {
  type    = string
  default = null
}

variable "flake" {
  type = string
}

variable "ssh_host" {
  type = string
}

variable "ssh_port" {
  type    = number
  default = null
}

variable "ssh_options" {
  type    = list(string)
  default = []
}

variable "build_on_remote" {
  type    = bool
  default = false
}

variable "substitute_on_remote" {
  type    = bool
  default = true
}

variable "upload_kexec_image" {
  type    = bool
  default = false
}

variable "kexec_image_version" {
  type    = string
  default = null
}

variable "kexec_image_arch" {
  type    = string
  default = null
}
