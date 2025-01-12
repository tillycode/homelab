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

    desktop = base ++ [
      config.fonts
      services.iwd
      services.printing
      services.bluetooth
      services.pipewire
      services.pcscd
      services.xfce
      services.gnome-keyring
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
  hmModules = selfHmModules ++ [
    inputs.vscode-server.homeModules.default
  ];

  ## ---------------------------------------------------------------------------
  ## HOSTS
  ## ---------------------------------------------------------------------------
  hosts = {
    hgh0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "4G";
        };
        sops.defaultSopsFile = ../lib/secrets/nodes/hgh0.yaml;
        networking.hostName = "hgh0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            [
              ../nixos/hosts/hgh0
            ]
            ++ suites.base
            ++ (with profiles; [
              system.systemd-boot
              system.kernel.qemu-guest
              system.disko
              services.sing-box
              services.tailscale
              services.nginx
              services.atticd
            ]);
        }
      )
    ];
    hgh1 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "2G";
        };
        sops.defaultSopsFile = ../lib/secrets/nodes/hgh1.yaml;
        networking.hostName = "hgh1";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ (with profiles; [
              system.systemd-boot
              system.kernel.qemu-guest
              system.disko
              services.postgresql
              services.nginx
              services.sing-box
              services.zitadel
              services.headscale
              services.tailscale
              services.coredns
              services.step-ca
              services.homepage-dashboard
            ]);
        }
      )
    ];
    hgh2 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "4G";
        };
        sops.defaultSopsFile = ../lib/secrets/nodes/hgh2.yaml;
        networking.hostName = "hgh2";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ (with profiles; [
              system.systemd-boot
              system.kernel.qemu-guest
              system.disko
              services.sing-box
              services.tailscale
            ]);
        }
      )
    ];
    sha0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "2G";
        };
        sops.defaultSopsFile = ../lib/secrets/nodes/sha0.yaml;
        networking.hostName = "sha0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ (with profiles; [
              system.kernel.qemu-guest
              system.disko
              services.sing-box
              services.tailscale
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
    sin0 = mkHost [
      {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAamaMcCAc7DhTJjDqBwXTWhewX0OI8vAuXLvc17yqK/"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIO4wL3BzfaMDOpbT/U/99MVQERjtzH2YxA6KAs7lwM"
        ];
        profiles.disko = {
          device = "/dev/vda";
          swapSize = "1G";
        };
        # sops.defaultSopsFile = ../lib/secrets/nodes/sin0.yaml;
        networking.hostName = "sin0";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            suites.base
            ++ (with profiles; [
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
        sops.defaultSopsFile = ../lib/secrets/nodes/desktop.yaml;
        networking.hostName = "desktop";
        nixpkgs.system = "x86_64-linux";
        system.stateVersion = "24.11";
      }
      (
        { profiles, suites, ... }:
        {
          imports =
            [
              ../nixos/hosts/desktop
            ]
            ++ suites.desktop
            ++ (with profiles; [
              config.nix-cache
              system.systemd-boot
              services.nginx
              services.sing-box
              services.tailscale
              services.github-runner
              virtualization.incus
              virtualization.podman
              users.sun
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
    sin0 = {
      ssh_host = "194.114.138.186";
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
        "-J"
        "root@${node.bastion_host}"
      ];
      profiles.system = {
        path = inputs.deploy-rs.lib.${system}.activate.nixos cfg;
      };
    };
  nodes = lib.pipe self.nixosConfigurations [
    (lib.filterAttrs (name: cfg: name != "desktop"))
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
    (lib.filterAttrs (name: cfg: name != "desktop"))
    (lib.mapAttrsToList mkHostCheck)
    (lib.fold lib.recursiveUpdate { })
  ];
}
