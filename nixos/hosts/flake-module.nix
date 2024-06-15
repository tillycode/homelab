{
  self,
  inputs,
  lib,
  ...
}:
{
  flake.nixosConfigurations.aliyun-hz2 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./aliyun-hz2 ];
    specialArgs = {
      inherit inputs;
    };
    system = "x86_64-linux";
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
