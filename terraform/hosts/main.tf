locals {
  nodes = [
    "hgh0",
    "sha0",
    "hkg0",
  ]
}

module "nixos_deploy" {
  for_each          = toset(local.nodes)
  source            = "../modules/nixos_deploy"
  node              = each.key
  working_directory = var.project_root
}
