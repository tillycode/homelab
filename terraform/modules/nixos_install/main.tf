resource "null_resource" "this" {
  triggers = var.triggers
  provisioner "local-exec" {
    environment = {
      NIXOS_ANYWHERE_VERSION = var.nixos_anywhere_version
      FLAKE                  = var.flake
      SSH_HOST               = var.ssh_host
      SSH_PORT               = var.ssh_port
      SSH_OPTIONS            = join("\n", var.ssh_options)
      BUILD_ON_REMOTE        = var.build_on_remote
      SUBSTITUTE_ON_REMOTE   = var.substitute_on_remote
      UPLOAD_KEXEC_IMAGE     = var.upload_kexec_image
      KEXEC_IMAGE_VERSION    = var.kexec_image_version
      KEXEC_IMAGE_ARCH       = var.kexec_image_arch
    }
    working_dir = var.working_directory
    command     = "${abspath(path.module)}/nixos-install.sh"
  }
}
