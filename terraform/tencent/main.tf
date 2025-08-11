## -----------------------------------------------------------------------------
## SSH KEY PAIR
## -----------------------------------------------------------------------------
resource "tencentcloud_key_pair" "github_action" {
  key_name   = "github_action"
  public_key = var.github_action_ssh_public_key
}

resource "tencentcloud_lighthouse_key_pair" "github_action" {
  key_name   = "github_action"
  public_key = var.github_action_ssh_public_key
}
