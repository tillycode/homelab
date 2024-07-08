{ inputs, ... }:
{
  # docs: https://numtide.github.io/devshell/modules_schema.html
  imports = [
    inputs.devshell.flakeModule
    inputs.git-hooks-nix.flakeModule
    ./deploy.nix
    ./treefmt.nix
    ./pre-commit.nix

    ## commands
    ./tofu-encryption.nix
  ];
  perSystem =
    { config, pkgs, ... }:
    {
      devshells.default = {
        devshell.packages = with pkgs; [
          opentofu
          cachix
          aws-vault
          terragrunt
          terraform-ls
          gh
          aliyun-cli
          jq
          sops
          ssh-to-age
        ];
        devshell.startup = {
          nixago.text = config.nixago.shellHook;
          pre-commit-hook.text = config.pre-commit.installationScript;
        };
      };
      nixago.configs = [ ];

      devshells.deploy = {
        devshell.motd = "Welcome to CI/CD shell";
        devshell.packages = with pkgs; [
          opentofu
          terragrunt
          jq
          sops
          ssh-to-age
          deploy-rs.deploy-rs
        ];
      };

      checks."devshell-default" = config.devShells.default;
      checks."devshell-deploy" = config.devShells.deploy;
    };
}
