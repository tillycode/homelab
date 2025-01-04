{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          self.overlays.default
          self.overlays.hacks
        ];
        config = {
          allowUnfree = true;
        };
      };
    };
}
