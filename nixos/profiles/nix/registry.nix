{ self, inputs, ... }:
{
  # nix.registry.p.flake = self;
  nix.settings.flake-registry = "/etc/nix/registry.json";
  nix.settings.nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
}
