{ config, pkgs, ... }:
{
  devshells.default = {
    devshell.packages = with pkgs; [
      opentofu
      cachix
      aws-vault
      awscli2
      terragrunt
      terraform-ls
      gh
      aliyun-cli
      jq
      sops
      ssh-to-age
      vault
      nvfetcher
      go-task
      python3
      uv
    ];
    devshell.startup = {
      nixago.text = config.nixago.shellHook;
      pre-commit-hook.text = config.pre-commit.installationScript;
    };
    commands = [
      {
        category = "deployment";
        name = "deploy";
        package = pkgs.deploy-rs.deploy-rs;
      }
    ];
  };

  checks."devshell/default" = config.devShells.default;
}
