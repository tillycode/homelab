{
  self,
  inputs,
  lib,
  ...
}:
let
  mkNode =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
    in
    {
      hostname = name;
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos cfg;
      };
    };
in
{
  flake.nixosConfigurations.hgh1 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./hgh1 ];
    specialArgs = {
      inherit inputs;
    };
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.hgh2 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./hgh2 ];
    specialArgs = {
      inherit inputs;
    };
    system = "x86_64-linux";
  };

  flake.deploy = {
    autoRollback = true;
    magicRollback = true;

    nodes = lib.mapAttrs mkNode self.nixosConfigurations;
  };

  flake.checks =
    let
      getSystem = cfg: cfg.pkgs.stdenv.hostPlatform.system;
      getHostTopLevel = name: cfg: {
        "${getSystem cfg}"."nixos/${name}" = cfg.config.system.build.toplevel;
      };
    in
    lib.pipe self.nixosConfigurations [
      (lib.mapAttrsToList getHostTopLevel)
      (lib.fold lib.recursiveUpdate { })
    ];
}
