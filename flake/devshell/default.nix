{ inputs, ... }:
{
  # docs: https://numtide.github.io/devshell/modules_schema.html
  imports = [
    inputs.devshell.flakeModule
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = {
    imports = [
      ./develop.nix
      ./deploy.nix
      ./treefmt.nix
      ./pre-commit.nix
      ./sops.nix
    ];
  };
}
