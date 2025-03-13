resource "shell_script" "deploy" {
  lifecycle_commands {
    create = "${path.module}/create.sh"
    read   = "${path.module}/read.sh"
    delete = ""
  }
  environment = {
    FLAKE             = var.flake
    NODE              = var.node
    WORKING_DIRECTORY = var.working_directory
  }
}
