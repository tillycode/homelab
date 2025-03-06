{ pkgs, config, ... }:
{
  devshells.deploy = {
    devshell.motd = "Welcome to CI/CD shell";
    devshell.packages = with pkgs; [
      terragrunt
      opentofu
      deploy-rs.deploy-rs
      sops
      jq
      ssh-to-age
      nix-fast-build
      gnupg
    ];
    devshell.startup.nixago.text = config.nixago.shellHook;
    env = [
      {
        name = "TG_NON_INTERACTIVE";
        value = "true";
      }
      {
        name = "TF_IN_AUTOMATION";
        value = "true";
      }
      {
        # FIXME: terragrunt is planning to change the envvar prefix to `TG_`.
        # And `run-all` subcommand is changed to `run --all`.
        # See https://github.com/gruntwork-io/terragrunt/issues/3445.
        name = "TG_QUEUE_EXCLUDE_DIR";
        value = "bootstrap,github-action,tencent";
      }
    ];
  };

  checks."devshell/deploy" = config.devShells.deploy;
}
