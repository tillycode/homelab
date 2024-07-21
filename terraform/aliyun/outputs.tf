resource "local_file" "known_hosts" {
  filename = var.known_hosts_output_file
  content = templatefile("${path.module}/known_hosts.tftpl", {
    known_hosts = [
      module.nixos_hgh1.known_hosts,
      module.nixos_hgh2.known_hosts,
    ]
  })
}

resource "local_file" "sops_config" {
  filename = var.sops_config_output_file
  content = templatefile("${path.module}/sops.yaml.tftpl", {
    github_action = var.github_action_sops_key_arn,
    hosts = {
      desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq"
      hgh1    = module.nixos_hgh1.age_public_key,
      hgh2    = module.nixos_hgh2.age_public_key,
    }
  })
}
