output "hosts" {
  value = {
    hgh0 = module.host_hgh0.metadata,
    hgh1 = module.host_hgh1.metadata,
    hgh2 = module.host_hgh2.metadata,
  }
}
