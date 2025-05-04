{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          self.overlays.default
        ];
        config = {
          allowUnfree = true;
        };
      };

      legacyPackages = pkgs;
    };
}
