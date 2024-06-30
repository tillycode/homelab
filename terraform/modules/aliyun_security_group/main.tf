resource "alicloud_security_group" "this" {
  name                = var.name
  vpc_id              = var.vpc_id
  description         = var.description
  tags                = var.tags
  security_group_type = "normal"
}

locals {
  ingress_rules = {
    for rule in flatten([
      for rule in var.ingress_rules : [
        for cidr in rule.cidrs : [
          for port in rule.ports : {
            protocol = rule.protocol
            port     = port
            cidr     = cidr
          }
        ]
      ]
    ]) :
    "${rule.protocol}:${rule.cidr}:${rule.port}" => rule
  }
}

resource "alicloud_security_group_rule" "this" {
  for_each          = local.ingress_rules
  type              = "ingress"
  ip_protocol       = each.value.protocol
  port_range        = "${each.value.port}/${each.value.port}"
  cidr_ip           = strcontains(each.value.cidr, ".") ? each.value.cidr : null
  ipv6_cidr_ip      = strcontains(each.value.cidr, ":") ? each.value.cidr : null
  nic_type          = "intranet"
  security_group_id = alicloud_security_group.this.id
}
