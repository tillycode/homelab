resource "local_file" "certificate" {
  filename = var.certificate_output_file
  content  = vault_pki_secret_backend_root_cert.root_2024.certificate
}
