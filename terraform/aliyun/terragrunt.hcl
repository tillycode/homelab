include "root" {
  path = find_in_parent_folders()
}

inputs = {
  project_root = get_path_to_repo_root()
  known_hosts_output_file = "${get_path_to_repo_root()}/generated/known_hosts"
}
