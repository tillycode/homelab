include "root" {
  path = find_in_parent_folders()
}

dependency "github_action" {
  config_path = "../github-action"
}

dependency "aliyun" {
  config_path = "../aliyun"
}

dependency "tencent" {
  config_path = "../tencent"
}

locals {
  sin0_public_ipv4 = "194.114.138.186"
  sin0_public_ipv6 = "2407:b9c0:e002:179:5054:ff:fee1:6eb7"
}

inputs = {
  project_root = get_path_to_repo_root()
  hosts = merge(
    dependency.aliyun.outputs.hosts,
    dependency.tencent.outputs.hosts,
    {
      sin0 = {
        boot   = "BIOS",
        arch   = "x86_64",
        region = "global",
        ssh = {
          host = local.sin0_public_ipv4,
        },
        addresses = {
          public_ipv4 = local.sin0_public_ipv4,
          public_ipv6 = local.sin0_public_ipv6,
        },
        resources = {
          cpu    = 1,
          memory = 1024,
          disks = [
            {
              name = "vda",
              size = 16,
            },
          ],
        },
      },
    },
  )
  headscale_hosts = {
    cn = "hgh0",
  }
  known_hosts_output_file    = "${get_path_to_repo_root()}/generated/known_hosts"
  sops_config_output_file    = "${get_path_to_repo_root()}/generated/sops.yaml"
  hosts_output_file          = "${get_path_to_repo_root()}/generated/hosts.json"
  github_action_sops_key_arn = dependency.github_action.outputs.aws_sops_key_arn
}
