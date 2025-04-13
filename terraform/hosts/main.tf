locals {
  nodes = [
    "hgh2",
    "sha0",
    "sin0",
  ]
}

module "nixos_deploy" {
  for_each          = toset(local.nodes)
  source            = "../modules/nixos_deploy"
  node              = each.key
  working_directory = var.project_root
}
