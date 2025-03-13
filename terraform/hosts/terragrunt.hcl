include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  extra_arguments "verbose" {
    commands = ["apply"]
    env_vars = {
      TF_LOG_PROVIDER = "INFO"
    }

  }
}

inputs = {
  project_root = get_path_to_repo_root()
}
