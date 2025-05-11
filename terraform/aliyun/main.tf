## -----------------------------------------------------------------------------
## NETWORK
## -----------------------------------------------------------------------------
module "vpc" {
  source          = "../modules/aliyun_vpc"
  vpc_name        = "hgh-vpc"
  vpc_description = "Hangzhou VPC"
  vpc_cidr        = "172.16.0.0/18"

  tags = {
    Terraform = "true"
  }

  vswitches = [
    {
      cidr        = "172.16.0.0/24"
      zone_id     = "cn-hangzhou-h"
      description = "Hangzhou VSwitch"
    }
  ]
}

resource "alicloud_route_entry" "hgh" {
  route_table_id        = module.vpc.route_table_id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "Instance"
  nexthop_id            = alicloud_instance.hgh0.id
}


## -----------------------------------------------------------------------------
## SSH KEY PAIR
## -----------------------------------------------------------------------------
resource "alicloud_key_pair" "github_action" {
  key_pair_name = "github-action"
  public_key    = var.github_action_ssh_public_key
}


## -----------------------------------------------------------------------------
## INSTANCES
## -----------------------------------------------------------------------------
module "sg" {
  source = "../modules/aliyun_security_group"

  name        = "hgh-sg"
  description = "Hangzhou Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      protocol = "icmp"
      cidrs    = ["0.0.0.0/0"]
      ports    = [-1]
    },
    {
      protocol = "tcp"
      cidrs    = ["0.0.0.0/0", "::/0"]
      ports = [
        22,    # SSH
        80,    # HTTP
        443,   # HTTPS
        25565, # Minecraft
      ]
    },
    {
      protocol = "udp"
      cidrs    = ["0.0.0.0/0", "::/0"]
      ports = [
        3478,  # STUN (used by tailscale)
        41641, # Tailscale
      ]
      port_ranges = [
        [6881, 6999] # BitTorrent
      ]
    }
  ]
}


resource "alicloud_eip_address" "hgh0" {
}

resource "alicloud_eip_association" "hgh0" {
  allocation_id = alicloud_eip_address.hgh0.id
  instance_type = "EcsInstance"
  instance_id   = alicloud_instance.hgh0.id
}

resource "alicloud_instance" "hgh0" {
  instance_name = "hgh0"

  instance_type   = "ecs.t6-c1m4.xlarge"
  image_id        = "ubuntu_22_04_uefi_x64_20G_alibase_20230515.vhd"
  security_groups = [module.sg.security_group_id]
  vswitch_id      = module.vpc.vswitch_ids[0]

  tags = {
    Terraform = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}
