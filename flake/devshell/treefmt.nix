{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";
        programs = {
          nixfmt-rfc-style.enable = true;
          prettier.enable = true;
          taplo.enable = true;
          terraform.enable = true;
          terraform.package = pkgs.opentofu;
        };
      };
    };
}
