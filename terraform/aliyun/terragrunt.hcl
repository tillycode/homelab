include "root" {
  path = find_in_parent_folders()
}

dependency "github_action" {
  config_path = "../github-action"
}

inputs = {
  github_action_ssh_public_key = dependency.github_action.outputs.github_ssh_public_key
  output_file    = "${get_path_to_repo_root()}/lib/data/aliyun.json"
}
