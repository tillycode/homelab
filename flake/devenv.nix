{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      devenv.shells.default = {
        packages = with pkgs; [
          config.treefmt.build.wrapper

          # scripts
          go-task
          nushell
          yq-go

          # deployment
          nixos-anywhere

          # packaging
          nvfetcher
        ];

        pre-commit.hooks.treefmt = {
          enable = true;
          packageOverrides.treefmt = config.treefmt.build.wrapper;
        };
      };
    };
}
