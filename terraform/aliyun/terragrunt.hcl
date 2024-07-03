include "root" {
  path = find_in_parent_folders()
}

# dependency "github_action" {
#   config_path = "${get_repo_root()}/terraform/github-action"
# }


inputs = {
  project_root = get_repo_root()
}
