output "hosts" {
  value = {
    hgh0 = module.host_hgh0.metadata,
    hgh1 = module.host_hgh1.metadata,
    hgh2 = module.host_hgh2.metadata,
  }
}

resource "local_file" "output" {
  filename = var.output_file
  content = jsonencode({
    nodes = {
      hgh0 = {
        ssh_host = local.hgh0_public_ip
      }
      hgh1 = {
        bastion_host = local.hgh0_public_ip,
        ssh_host     = alicloud_instance.hgh1.private_ip,
      }
      hgh2 = {
        bastion_host = local.hgh0_public_ip,
        ssh_host     = alicloud_instance.hgh2.private_ip,
      }
    }
  })
}
