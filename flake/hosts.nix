{ inputs
, lib
, self
, ...
}:
let
  selfNixosModules = lib.collect lib.isPath (inputs.haumea.lib.load {
    src = ../nixos/modules;
    loader = inputs.haumea.lib.loaders.path;
  });
  nixosModules = selfNixosModules ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
  ];
  nixosProfiles = inputs.haumea.lib.load {
    src = ../nixos/profiles;
    loader = inputs.haumea.lib.loaders.path;
  };
  nixosSuites = with nixosProfiles; rec {
    nixSettings = [
      nix.gc
      nix.optimise
      nix.registry
      nix.settings
    ];

    base = nixSettings ++ [
      networking.systemd
      services.openssh
    ];

    aliyunServer = base ++ [ system.aliyun ];
  };

  nixosSpecialArgs = {
    inherit inputs self;
    profiles = nixosProfiles;
    suites = nixosSuites;
  };

  mkHost =
    name:
    { system
    , nixpkgs ? inputs.nixpkgs
    , specialArgs ? nixosSpecialArgs
    ,
    }:
    nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = nixosModules ++ [
        ../nixos/hosts/${name}
        { networking.hostName = "${name}"; }
      ];
    };

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

  mkHostCheck =
    name: cfg:
    let
      system = cfg.pkgs.stdenv.hostPlatform.system;
      toplevel = cfg.config.system.build.toplevel;
    in
    {
      "${system}"."nixos/${name}" = toplevel;
    };
in
{
  flake.nixosConfigurations = lib.mapAttrs mkHost {
    hgh1 = {
      system = "x86_64-linux";
    };
    hgh2 = {
      system = "x86_64-linux";
    };
  };

  flake.deploy = {
    autoRollback = true;
    magicRollback = true;

    nodes = lib.mapAttrs mkNode self.nixosConfigurations;
  };

  flake.checks = lib.pipe self.nixosConfigurations [
    (lib.mapAttrsToList mkHostCheck)
    (lib.fold lib.recursiveUpdate { })
  ];
}
