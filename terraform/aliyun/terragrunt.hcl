include "root" {
  path = find_in_parent_folders()
}

dependency "github_action" {
  config_path = "../github-action"
}

inputs = {
  project_root = get_path_to_repo_root()
  known_hosts_output_file = "${get_path_to_repo_root()}/generated/known_hosts"
  sops_config_output_file = "${get_path_to_repo_root()}/generated/sops.yaml"
  github_action_ssh_public_key = dependency.github_action.outputs.github_ssh_public_key
  github_action_sops_key_arn = dependency.github_action.outputs.aws_sops_key_arn
}
