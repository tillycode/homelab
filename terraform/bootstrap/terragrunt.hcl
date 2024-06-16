terraform {
  extra_arguments "tf_encryption" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "refresh",
      "show",
      "state",
      "output"
    ]
    env_vars = {
      TF_ENCRYPTION = run_cmd("--terragrunt-quiet", "tofu-encryption")
    }
  }
}
