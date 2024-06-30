variable "vpc_id" {
  type    = string
  default = null
}

variable "name" {
  type    = string
  default = ""
}

variable "description" {
  type    = string
  default = "Security Group managed by Terraform"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ingress_rules" {
  type = list(object({
    protocol = string
    cidrs    = list(string)
    ports    = list(number)
  }))
  default = []
}
