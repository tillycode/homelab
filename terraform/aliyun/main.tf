
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

resource "alicloud_vpc_ipv4_gateway" "hgh" {
  vpc_id = module.vpc.vpc_id
}

resource "alicloud_route_entry" "hgh" {
  route_table_id        = module.vpc.route_table_id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "Ipv4Gateway"
  nexthop_id            = alicloud_vpc_ipv4_gateway.hgh.id
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

module "hgh2_install" {
  source = "../modules/nixos_install"
  triggers = {
    instance_id = alicloud_instance.hgh2.id
  }
  working_directory = var.project_root

  flake       = "git+file:.#aliyun-hz2"
  ssh_host    = "root@${alicloud_instance.hgh2.private_ip}"
  ssh_options = ["ProxyJump=root@hz0.szp15.com"]

  substitute_on_remote = false
  upload_kexec_image   = true
}
