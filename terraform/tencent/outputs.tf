output "hosts" {
  value = {
    sha0 = module.host_sha0.metadata,
  }
}
