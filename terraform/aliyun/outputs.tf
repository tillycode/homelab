resource "local_file" "known_hosts" {
  filename = var.known_hosts_output_file
  content = templatefile("${path.module}/known_hosts.tftpl", {
    known_hosts = [
      module.nixos_hgh1.known_hosts,
      module.nixos_hgh2.known_hosts,
    ]
  })
}
