{ inputs, ... }:
{
  # docs: https://numtide.github.io/devshell/modules_schema.html
  imports = [
    inputs.devshell.flakeModule
    inputs.git-hooks-nix.flakeModule
    ./deploy.nix
    ./treefmt.nix
    ./pre-commit.nix
    ./tofu-encryption.nix
  ];
  perSystem =
    { config, pkgs, ... }:
    {
      devshells.default = {
        devshell.packages = with pkgs; [
          opentofu
          aws-vault
          sops
        ];
        devshell.startup = {
          nixago.text = config.nixago.shellHook;
          pre-commit-hook.text = config.pre-commit.installationScript;
        };
      };
      nixago.configs = [ ];
    };
}
