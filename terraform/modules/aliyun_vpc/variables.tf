variable "vpc_name" {
  type    = string
  default = "TF-VPC"
}

variable "vpc_description" {
  type    = string
  default = "VPC managed by Terraform"
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/12"
}

variable "vpc_enable_ipv6" {
  type    = bool
  default = true

}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vswitches" {
  type = list(object({
    name                 = optional(string, "TF-VSwitch")
    description          = optional(string, "VSwitch managed by Terraform")
    cidr                 = string
    zone_id              = string
    enable_ipv6          = optional(bool, true)
    ipv6_cidr_block_mask = optional(number, 64)
  }))
  default = []
}
