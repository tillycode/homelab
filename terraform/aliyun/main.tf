
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
      ports    = [22, 80, 443, 25565]
    },
    {
      protocol = "udp"
      cidrs    = ["0.0.0.0/0", "::/0"]
      ports    = [3478]
    }
  ]
}

resource "alicloud_key_pair" "github_action" {
  key_pair_name = "github-action"
  public_key    = var.github_action_ssh_public_key
}


resource "alicloud_instance" "hgh0" {
  instance_name = "hgh0"

  instance_type   = "ecs.e-c1m4.large"
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

resource "alicloud_instance" "hgh1" {
  instance_name = "hgh1"

  instance_type     = "ecs.e-c1m1.large"
  image_id          = "ubuntu_22_04_uefi_x64_20G_alibase_20230515.vhd"
  security_groups   = [module.sg.security_group_id]
  vswitch_id        = module.vpc.vswitch_ids[0]
  renewal_status    = "AutoRenewal"
  auto_renew_period = 12

  tags = {
    Terraform = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_instance" "hgh2" {
  instance_name = "hgh2"

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

locals {
  hgh0_public_ip = "47.96.145.133"
  sin0_public_ip = "194.114.138.186"
}

module "nixos_hgh0" {
  source = "../modules/nixos"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh0.id
  }

  working_directory = var.project_root
  attribute         = "hgh0"
  ssh_host          = local.hgh0_public_ip
  push_to_remote    = true
}

module "nixos_hgh1" {
  source = "../modules/nixos"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh1.id
  }

  working_directory = var.project_root
  attribute         = "hgh1"
  ssh_host          = alicloud_instance.hgh1.private_ip
  bastion_host      = local.hgh0_public_ip
  push_to_remote    = true
}

module "nixos_hgh2" {
  source = "../modules/nixos"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh2.id
  }

  working_directory = var.project_root
  attribute         = "hgh2"
  ssh_host          = alicloud_instance.hgh2.private_ip
  bastion_host      = local.hgh0_public_ip
  push_to_remote    = true
}


module "nixos_sin0" {
  source = "../modules/nixos"

  working_directory = var.project_root
  attribute         = "sin0"
  ssh_host          = local.sin0_public_ip
  push_to_remote    = true
}
