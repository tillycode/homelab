{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";
        programs = {
          nixfmt-rfc-style.enable = true;
          prettier.enable = true;
        };
      };
    };
}
