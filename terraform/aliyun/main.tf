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
      ports    = [22, 80, 443, 25565]
    },
    {
      protocol = "udp"
      cidrs    = ["0.0.0.0/0", "::/0"]
      ports    = [3478]
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

  instance_type   = "ecs.e-c1m1.large"
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

## -----------------------------------------------------------------------------
## METADATA
## -----------------------------------------------------------------------------
locals {
  hgh0_public_ip = alicloud_eip_address.hgh0.ip_address
}

module "host_hgh0" {
  source = "../modules/host_metadata"

  boot   = "UEFI"
  region = "cn"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh0.id
  }
  public_ipv4  = local.hgh0_public_ip
  private_ipv4 = alicloud_instance.hgh0.private_ip
  public_ipv6  = tolist(alicloud_instance.hgh0.ipv6_addresses)[0]
  cpu          = alicloud_instance.hgh0.cpu
  memory       = alicloud_instance.hgh0.memory
  disks = [
    {
      name = "vda"
      size = alicloud_instance.hgh0.system_disk_size
    }
  ]
}


module "host_hgh1" {
  source = "../modules/host_metadata"

  boot   = "UEFI"
  region = "cn"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh1.id
  }
  bastion_host = local.hgh0_public_ip
  public_ipv4  = alicloud_instance.hgh1.public_ip
  private_ipv4 = alicloud_instance.hgh1.private_ip
  public_ipv6  = tolist(alicloud_instance.hgh1.ipv6_addresses)[0]
  cpu          = alicloud_instance.hgh1.cpu
  memory       = alicloud_instance.hgh1.memory
  disks = [
    {
      name = "vda"
      size = alicloud_instance.hgh1.system_disk_size
    }
  ]
}

module "host_hgh2" {
  source = "../modules/host_metadata"

  boot   = "UEFI"
  region = "cn"
  reinstall_triggers = {
    instance_id = alicloud_instance.hgh2.id
  }
  bastion_host = local.hgh0_public_ip
  private_ipv4 = alicloud_instance.hgh2.private_ip
  public_ipv6  = tolist(alicloud_instance.hgh2.ipv6_addresses)[0]
  cpu          = alicloud_instance.hgh2.cpu
  memory       = alicloud_instance.hgh2.memory
  disks = [
    {
      name = "vda"
      size = alicloud_instance.hgh2.system_disk_size
    }
  ]
}
