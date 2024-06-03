{ inputs, self, ... }:
{
  perSystem =
    { system, inputs', ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          (_: _: { nixos-anywhere = inputs'.nixos-anywhere.packages.nixos-anywhere; })
        ];
        config = {
          allowUnfree = true;
        };
      };
    };
}
