resource "local_file" "known_hosts" {
  filename = var.known_hosts_output_file
  content = templatefile("${path.module}/known_hosts.tftpl", {
    known_hosts = [for module in values(module.nixos) : module.known_hosts]
  })
}

resource "local_file" "sops_config" {
  filename = var.sops_config_output_file
  content = templatefile("${path.module}/sops.yaml.tftpl", {
    github_action = var.github_action_sops_key_arn,
    hosts = merge(
      { for name, module in module.nixos : name => module.age_public_key },
      {
        desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq"
      },
    )
  })
}

resource "local_file" "hosts" {
  filename = var.hosts_output_file
  content = jsonencode([
    for name, module in var.hosts : merge({
      hostname = name
    }, module)
  ])
}
