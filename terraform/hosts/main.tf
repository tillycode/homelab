## -----------------------------------------------------------------------------
## NIXOS DEPLOYMENT
## -----------------------------------------------------------------------------
module "nixos" {
  for_each           = var.hosts
  source             = "../modules/nixos"
  reinstall_triggers = each.value.reinstall_triggers
  working_directory  = var.project_root
  attribute          = each.key
  ssh_host           = each.value.ssh.host
  bastion_host       = each.value.ssh.bastion_host
  push_to_remote     = true
}

## -----------------------------------------------------------------------------
## HEADSCALE IP ASSIGNMENT
## -----------------------------------------------------------------------------
data "external" "headscale" {
  for_each = var.headscale_hosts
  program  = ["${path.module}/headscale_nodes_list.sh"]
  query = {
    ssh_host    = var.hosts[each.value].ssh.host
    known_hosts = module.nixos[each.value].known_hosts
  }
}


locals {
  headscale_nodes = merge([
    for nodes in values(data.external.headscale) : {
      for node in jsondecode(nodes.result["headscale_nodes"]) :
      node.name => node.addresses
    }
  ]...)
}
