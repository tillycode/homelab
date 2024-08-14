include "root" {
  path = find_in_parent_folders()
}

inputs = {
  certificate_output_file = "${get_path_to_repo_root()}/generated/k8s-szp-io.crt"
}
