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

## -----------------------------------------------------------------------------
## METADATA
## -----------------------------------------------------------------------------
module "host_sha0" {
  source = "../modules/host_metadata"

  boot   = "BIOS"
  region = "cn"
  reinstall_triggers = {
    instance_id = tencentcloud_lighthouse_instance.sha0.id
  }
  public_ipv4 = tencentcloud_lighthouse_instance.sha0.public_addresses[0]
  cpu         = 2
  memory      = 4096
  disks = [
    {
      name = "vda"
      size = 70
    }
  ]
}
