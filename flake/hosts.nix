{
  inputs,
  lib,
  self,
  getSystem,
  ...
}:
let
  ## ---------------------------------------------------------------------------
  ## NIXOS MODULES
  ## ---------------------------------------------------------------------------
  nixosProfiles = loadProfiles ../nixos/profiles;
  nixosSuites = with nixosProfiles; rec {
    # base should not require sops
    base = [
      config.bbr
      config.bootloader
      config.home-manager
      config.persistent-common
      config.nix
      config.root-ca
      config.sudo
      config.firewall
      services.networkd
      services.nix-optimise
      services.nix-gc
      services.resolved
      services.sshd
      programs.cli-tools
    ];

    domestic = [
      config.nix-cache
      services.sing-box
      services.tailscale
    ];

    desktop = base ++ [
      config.fonts
      services.iwd
      services.printing
      services.bluetooth
      services.pipewire
      services.pcscd
      services.xfce
      services.gnome-keyring
      programs.nix-ld
      programs.steam
      programs."1password"
    ];
  };

  selfNixosModules = loadModules ../nixos/modules;
  nixosModules = selfNixosModules ++ [
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.nix-minecraft.nixosModules.minecraft-servers
    (
      { config, ... }:
      {
        nixpkgs.pkgs = (getSystem config.nixpkgs.system).allModuleArgs.pkgs;
      }
    )
    {
      home-manager = {
        sharedModules = hmModules;
        extraSpecialArgs = {
          inherit inputs self;
          profiles = hmProfiles;
        };
      };
    }
  ];

  ## ---------------------------------------------------------------------------
  ## HOME MANAGER MODULES
  ## ---------------------------------------------------------------------------
  hmProfiles = loadProfiles ../home-manager/profiles;

  selfHmModules = loadModules ../home-manager/modules;
  hmModules = selfHmModules;

  ## ---------------------------------------------------------------------------
  ## HOSTS
  ## ---------------------------------------------------------------------------
  hosts = {
    hgh0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNlekmLqIMn8zTkjU2sU4StemRV+wQvoMMvqmIIJxT6"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "4G";
        };
        sops.defaultSopsFile = ../secrets/nodes/hgh0.yaml;
        networking.hostName = "hgh0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";

        networking.nat = {
          enable = true;
          internalInterfaces = [ "ens5" ];
          externalInterface = "ens5";
        };
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ suites.domestic
            ++ (with profiles; [
              config.no-nixos-doc
              services.aria2
              services.atticd
              services.acme-dns
              services.blog
              services.coredns
              services.cloudreve
              services.cloudreve-cname
              services.firefly-iii
              services.grafana
              services.headscale
              services.homepage-dashboard
              services.loki
              services.minecraft-gate
              services.nginx
              services.node-exporter
              services.postgresql
              services.prometheus
              services.restic
              services.rke2-agent
              services.rke2-ingress
              services.step-ca
              services.vector
              services.xray
              services.zitadel
              system.systemd-boot
              system.kernel.qemu-guest
              system.disko
            ]);
        }
      )
    ];
    sha0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNlekmLqIMn8zTkjU2sU4StemRV+wQvoMMvqmIIJxT6"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "2G";
        };
        sops.defaultSopsFile = ../secrets/nodes/sha0.yaml;
        networking.hostName = "sha0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ suites.domestic
            ++ (with profiles; [
              config.no-nixos-doc
              services.node-exporter
              services.vector
              system.kernel.qemu-guest
              system.disko
            ]);
        }
      )
    ];
    # To make nixos-anywhere work, please manually turn on zramswap and increase
    # writable nix store size before the disko phase.
    #
    #     mount -o remount,size=70% -t tmpfs tmpfs /nix/.rw-store
    #     modprobe zram
    #     zramctl /dev/zram0 --algorithm zstd --size 800000KiB
    #     mkswap -U clear /dev/zram0
    #     swapon --discard --priority 100 /dev/zram0
    #
    hkg0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNlekmLqIMn8zTkjU2sU4StemRV+wQvoMMvqmIIJxT6"
        ];
        profiles.disko = {
          device = "/dev/sda";
          swapSize = "2G";
        };
        networking.hostName = "hkg0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
        systemd.network.networks."10-eth0" = {
          name = "ens18";
          DHCP = "yes";
          address = [ "46.232.54.69/32" ];
          dns = [ "1.1.1.1" ];
          routes = [
            {
              Gateway = [ "100.100.0.0" ];
              GatewayOnLink = "yes";
            }
          ];
        };
        sops.defaultSopsFile = ../secrets/nodes/hkg0.yaml;
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ (with profiles; [
              config.no-nixos-doc
              services.headscale-global
              services.nginx
              services.node-exporter
              services.sing-box-global
              services.tailscale-global
              services.xray-global
              services.vector
              system.kernel.qemu-guest
              system.disko
            ]);
        }
      )
    ];
    desktop = mkHost [
      {
        time.timeZone = "Asia/Shanghai";
        # add options for enable sopsFile, enable imports
        sops.defaultSopsFile = ../secrets/nodes/desktop.yaml;
        networking.hostName = "desktop";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
        boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            [
              ../nixos/hosts/desktop
            ]
            ++ suites.desktop
            ++ suites.domestic
            ++ (with profiles; [
              system.systemd-boot
              services.minecraft
              services.nginx
              services.node-exporter
              services.github-runner
              services.gha-cache-server
              services.minio
              services.restic
              services.rke2-bootstrap
              services.rke2-ingress
              services.vector
              virtualization.incus
              virtualization.podman
              users.sun
            ]);
        }
      )
    ];
    laptop = mkHost [
      {
        time.timeZone = "Asia/Shanghai";
        sops.defaultSopsFile = ../secrets/nodes/laptop.yaml;
        networking.hostName = "laptop";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "25.05";
        profiles.disko = {
          device = "/dev/nvme0n1";
          swapSize = "32G";
        };
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            [
              ../nixos/hosts/laptop
            ]
            ++ suites.desktop
            ++ suites.domestic
            ++ (with profiles; [
              services.power-profiles-daemon
              services.vector
              system.systemd-boot
              system.disko
              virtualization.podman
              users.sun
            ]);
        }
      )
    ];
    r2s = mkHost [
      {
        time.timeZone = "Asia/Shanghai";
        sops.defaultSopsFile = ../secrets/nodes/r2s.yaml;
        networking.hostName = "r2s";
        nixpkgs.system = "aarch64-linux";
        system.stateVersion = "25.05";
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNlekmLqIMn8zTkjU2sU4StemRV+wQvoMMvqmIIJxT6"
        ];
        networking.wireless.iwd.enable = true;

      }
      (
        { suites, profiles, ... }:
        {
          imports =
            [
              ../nixos/hosts/r2s
            ]
            ++ suites.base
            ++ suites.domestic
            ++ (with profiles; [
              config.no-nixos-doc
              services.node-exporter
              services.vector
            ]);
        }
      )
    ];
  };
  mkHost =
    modules:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
        profiles = nixosProfiles;
        suites = nixosSuites;
      };
      modules = nixosModules ++ modules;
    };

  ## ---------------------------------------------------------------------------
  ## DEPLOY
  ## ---------------------------------------------------------------------------
  nodeDeployOverrides = {
    hkg0 = {
      ssh_host = "hkg0.eh578599.xyz";
      bastion_host = null;
    };
  };
  mkNode =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
      node = nodeDeployOverrides.${name} or null;
    in
    {
      hostname = if node == null || node.ssh_host == null then name else node.ssh_host;
      sshUser = "root";
      sshOpts = lib.optionals (node != null && node.bastion_host != null) [
        "-o"
        "ProxyJump=root@${node.bastion_host}"
      ];
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos cfg;
      };
    };
  nodes = lib.pipe self.nixosConfigurations [
    (lib.filterAttrs (name: cfg: name != "desktop" && name != "laptop"))
    (lib.mapAttrs mkNode)
  ];

  ## ---------------------------------------------------------------------------
  ## HELPERS
  ## ---------------------------------------------------------------------------
  mkHostCheck =
    name: cfg:
    let
      system = cfg.pkgs.stdenv.hostPlatform.system;
      toplevel = cfg.config.system.build.toplevel;
    in
    {
      "${system}"."nixos/${name}" = toplevel;
    };
  loadModules =
    src:
    lib.collect lib.isPath (
      inputs.haumea.lib.load {
        src = src;
        loader = inputs.haumea.lib.loaders.path;
      }
    );
  loadProfiles =
    src:
    inputs.haumea.lib.load {
      inherit src;
      loader = inputs.haumea.lib.loaders.path;
    };
in
{
  flake.nixosConfigurations = hosts;

  flake.deploy = {
    autoRollback = false;
    magicRollback = false;
    inherit nodes;
  };

  flake.checks = lib.pipe self.nixosConfigurations [
    (lib.mapAttrsToList mkHostCheck)
    (lib.fold lib.recursiveUpdate { })
  ];
}
