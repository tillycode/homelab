## -----------------------------------------------------------------------------
## FLAKE OPTIONS
## -----------------------------------------------------------------------------

variable "working_directory" {
  type    = string
  default = null
}

variable "flake" {
  type = string
  # FIXME: git+file:. broken in nix 2.19 (NixOS/nix#9708)
  # default = "git+file:.?shallow=1"
  default = ".?shallow=1"
}

variable "attribute" {
  type = string
}

## -----------------------------------------------------------------------------
## CONNECTION OPTIONS
## -----------------------------------------------------------------------------

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_host" {
  type = string
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "bastion_user" {
  type    = string
  default = "root"
}

variable "bastion_host" {
  type    = string
  default = null
}

variable "bastion_port" {
  type    = number
  default = 22
}

## -----------------------------------------------------------------------------
## COMMON OPTIONS
## -----------------------------------------------------------------------------

variable "push_to_remote" {
  type    = bool
  default = false
}

variable "build_on_remote" {
  type    = bool
  default = false
}

## -----------------------------------------------------------------------------
## REINSTALL OPTIONS
## -----------------------------------------------------------------------------

variable "reinstall" {
  type    = bool
  default = true
}

variable "reinstall_triggers" {
  type    = map(string)
  default = {}
}

variable "nixos_anywhere_version" {
  type        = string
  description = "See https://github.com/nix-community/nixos-anywhere/tags."
  default     = "1.3.0"
}

variable "nixos_images_version" {
  type        = string
  description = "See https://github.com/nix-community/nixos-images/tags."
  default     = "nixos-24.05"
}

## -----------------------------------------------------------------------------
## DEPLOY OPTIONS
## -----------------------------------------------------------------------------

variable "deploy" {
  type    = bool
  default = true
}
