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
          taplo.enable = true;
        };
        settings.formatter = {
          nixfmt-rfc-style.excludes = [ "generated.nix" ];
        };
      };
    };
}
