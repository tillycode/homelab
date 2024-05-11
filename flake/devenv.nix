{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];

  perSystem =
    { config, ... }:
    {
      devenv.shells.default = {
        packages = [ config.treefmt.build.wrapper ];

        pre-commit.hooks.treefmt = {
          enable = true;
          packageOverrides.treefmt = config.treefmt.build.wrapper;
        };
      };
    };
}
