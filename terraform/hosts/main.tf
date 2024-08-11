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
