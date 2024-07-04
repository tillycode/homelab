{
  self,
  inputs,
  lib,
  ...
}:
{
  flake.nixosConfigurations.hgh2 = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./hgh2 ];
    specialArgs = {
      inherit inputs;
    };
    system = "x86_64-linux";
  };

  flake.deploy =
    let
      cfg = self.nixosConfigurations.hgh2;
      system = cfg.pkgs.stdenv.hostPlatform.system;
      deployLib = inputs.deploy-rs.lib.${system};
    in
    {
      autoRollback = true;
      magicRollback = true;

      nodes = {
        hgh2 = {
          hostname = "172.16.0.78";
          sshUser = "root";
          sshOpts = [
            "-o"
            "ProxyJump=root@hz0.szp15.com"
          ];
          fastConnection = true;
          remoteBuild = false;

          profiles.system = {
            path = deployLib.activate.nixos cfg;
          };
        };
      };
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
