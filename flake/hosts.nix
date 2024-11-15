{
  inputs,
  lib,
  self,
  getSystem,
  ...
}:
let
  selfNixosModules = lib.collect lib.isPath (
    inputs.haumea.lib.load {
      src = ../nixos/modules;
      loader = inputs.haumea.lib.loaders.path;
    }
  );

  nixosModules = selfNixosModules ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
  ];
  nixosProfiles = inputs.haumea.lib.load {
    src = ../nixos/profiles;
    loader = inputs.haumea.lib.loaders.path;
  };
  nixosSuites = with nixosProfiles; rec {
    base = [
      config.home-manager
      config.i18n
      config.locale
      config.nix
      misc.node-facts
      programs.cli-tools
      security.pki
      security.sudo
      services.misc.nix-gc
      services.misc.nix-optimise
      services.networking.networkd
      services.networking.sshd
      system.boot.loader
      system.persist.common
    ];

    domestic = base ++ [
      services.networking.sing-box-client
      services.networking.tailscale
      services.networking.tailscale-patched
    ];

    aliyun = domestic ++ [
      system.boot.efi
      system.disk.aliyun
    ];

    misaka = base ++ [ system.disk.misaka ];

    desktop = domestic ++ [
      config.fonts
      hardware.nvidia
      i18n.input-method.fcitx
      programs.desktop
      programs.nix-dev
      services.desktop.pipewire
      services.desktop.xfce
      services.hardware.bluetooth
      services.networking.iwd
      services.printing
      system.boot.efi
      users.sun
      virtualisation.lxd
      virtualisation.podman
    ];
  };

  nixosSpecialArgs = {
    inherit inputs self;
    profiles = nixosProfiles;
    suites = nixosSuites;
  };

  mkHost =
    name:
    {
      system,
      nixpkgs ? inputs.nixpkgs,
      specialArgs ? nixosSpecialArgs,
    }:
    nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = nixosModules ++ [
        ../nixos/hosts/${name}
        { networking.hostName = "${name}"; }
        {
          imports = [ nixpkgs.nixosModules.readOnlyPkgs ];
          nixpkgs = {
            pkgs = (getSystem system).allModuleArgs.pkgs;
          };
        }
      ];
    };

  mkNode =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
      node = self.lib.data.nodes.${name} or null;
    in
    {
      hostname = if node == null || node.ssh_host == null then name else node.ssh_host;
      sshUser = "root";
      sshOpts = lib.optionals (node != null && node.bastion_host != null) [
        "-J"
        "root@${node.bastion_host}"
      ];
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos cfg;
      };
    };

  mkHostCheck =
    name: cfg:
    let
      system = cfg.pkgs.stdenv.hostPlatform.system;
      toplevel = cfg.config.system.build.toplevel;
    in
    {
      "${system}"."nixos/${name}" = toplevel;
    };

  # v2 is the next version
  selfNixosModulesV2 = lib.collect lib.isPath (
    inputs.haumea.lib.load {
      src = ../nixos/modules-v2;
      loader = inputs.haumea.lib.loaders.path;
    }
  );

  nixosModulesV2 = selfNixosModulesV2 ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
  ];

  nixosProfilesV2 = inputs.haumea.lib.load {
    src = ../nixos/profiles-v2;
    loader = inputs.haumea.lib.loaders.path;
  };

  mkHostV2 =
    name: profiles:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = nixosSpecialArgs;
      modules =
        nixosModulesV2
        ++ (lib.map (
          p: if lib.isString p then lib.getAttrFromPath (lib.splitString "." p) nixosProfilesV2 else p
        ) profiles);
    };
in
{
  flake.nixosConfigurations =
    (lib.mapAttrs mkHost {
      desktop = {
        system = "x86_64-linux";
      };
      hgh0 = {
        system = "x86_64-linux";
      };
      hgh2 = {
        system = "x86_64-linux";
      };
      sin0 = {
        system = "x86_64-linux";
      };
      sha0 = {
        system = "x86_64-linux";
      };
    })
    // (lib.mapAttrs (n: cfg: mkHostV2 n cfg.profiles) self.lib.data.nodes);

  flake.deploy = {
    # autoRollback = true;
    magicRollback = true;

    nodes = lib.mapAttrs mkNode self.nixosConfigurations;
  };

  flake.checks = lib.pipe self.nixosConfigurations [
    (lib.filterAttrs (name: cfg: name != "desktop"))
    (lib.mapAttrsToList mkHostCheck)
    (lib.fold lib.recursiveUpdate { })
  ];
}
