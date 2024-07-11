resource "null_resource" "reinstall" {
  count    = var.reinstall ? 1 : 0
  triggers = var.reinstall_triggers
  provisioner "local-exec" {
    command = "${path.module}/reinstall.sh"
    environment = {
      flake                  = var.flake
      attribute              = var.attribute
      ssh_user               = var.ssh_user
      ssh_host               = var.ssh_host
      ssh_port               = var.ssh_port
      bastion_user           = var.bastion_user
      bastion_host           = var.bastion_host
      bastion_port           = var.bastion_port
      push_to_remote         = var.push_to_remote
      build_on_remote        = var.build_on_remote
      nixos_anywhere_version = var.nixos_anywhere_version
      nixos_images_version   = var.nixos_images_version
      working_dir            = var.working_directory
    }
  }
}

data "external" "keyscan" {
  depends_on = [null_resource.reinstall]
  program    = ["${path.module}/keyscan.sh"]
  query = {
    ssh_host     = var.ssh_host
    ssh_port     = var.ssh_port
    bastion_user = var.bastion_user
    bastion_host = var.bastion_host
    bastion_port = var.bastion_port
  }
}

data "external" "build" {
  program = ["${path.module}/build.sh"]
  query = {
    flake       = var.flake
    attribute   = "nixosConfigurations.\"${var.attribute}\".config.system.build.toplevel"
    working_dir = var.working_directory
  }
}

locals {
  known_hosts    = data.external.keyscan.result.known_hosts
  age_public_key = data.external.keyscan.result.age_public_key
  build          = data.external.build.result.out
}

resource "null_resource" "deploy" {
  count = var.deploy ? 1 : 0
  triggers = {
    known_hosts = local.known_hosts
    build       = local.build
  }
  provisioner "local-exec" {
    command = "${path.module}/deploy.sh"
    environment = {
      known_hosts     = local.known_hosts
      flake           = var.flake
      attribute       = var.attribute
      ssh_user        = var.ssh_user
      ssh_host        = var.ssh_host
      ssh_port        = var.ssh_port
      bastion_user    = var.bastion_user
      bastion_host    = var.bastion_host
      bastion_port    = var.bastion_port
      push_to_remote  = var.push_to_remote
      build_on_remote = var.build_on_remote
      working_dir     = var.working_directory
    }
  }
}
