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

## -----------------------------------------------------------------------------
## INSTANCES
## -----------------------------------------------------------------------------
resource "tencentcloud_lighthouse_instance" "sha0" {
  blueprint_id  = "lhbp-1l4ptuvm"
  bundle_id     = "bundle_starter_mc_promo_med4_02"
  renew_flag    = "NOTIFY_AND_MANUAL_RENEW"
  instance_name = "sha0"
}
