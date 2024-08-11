output "metadata" {
  value = {
    boot   = var.boot,
    arch   = var.arch,
    region = var.region,
    ssh = {
      host         = coalesce(var.ssh_host, var.bastion_host != null ? var.private_ipv4 : var.public_ipv4),
      bastion_host = var.bastion_host,
    }
    reinstall_triggers = var.reinstall_triggers,
    addresses = {
      public_ipv4  = var.public_ipv4,
      private_ipv4 = var.private_ipv4,
      public_ipv6  = var.public_ipv6,
    },
    resources = {
      cpu    = var.cpu,
      memory = var.memory,
      disks  = var.disks,
    },
  }
}
