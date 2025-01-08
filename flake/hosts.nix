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
  };

  nixosProfilesV2 = inputs.haumea.lib.load {
    src = ../nixos/profiles-v2;
    loader = inputs.haumea.lib.loaders.path;
  };

  nixosSuitesV2 = with nixosProfilesV2; rec {
    # base should always doesn't require sops
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

  hmProfiles = inputs.haumea.lib.load {
    src = ../home-manager/profiles;
    loader = inputs.haumea.lib.loaders.path;
  };

  selfHmModules = lib.collect lib.isPath (
    inputs.haumea.lib.load {
      src = ../home-manager/modules;
      loader = inputs.haumea.lib.loaders.path;
    }
  );

  hmModules = selfHmModules ++ [
    inputs.vscode-server.homeModules.default
  ];

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

  mkHostV2 =
    modules:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
        profiles = nixosProfilesV2;
        suites = nixosSuitesV2;
      };
      modules = nixosModulesV2 ++ modules;
    };
in
{
  flake.nixosConfigurations =
    (lib.mapAttrs mkHost {
      sin0 = {
        system = "x86_64-linux";
      };
    })
    // {
      hgh0 = mkHostV2 [
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
              ]);
          }
        )
      ];
      hgh1 = mkHostV2 [
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
              ]);
          }
        )
      ];
      hgh2 = mkHostV2 [
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
      sha0 = mkHostV2 [
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
      sin0 = mkHostV2 [
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
      desktop = mkHostV2 [
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
                system.systemd-boot
                services.nginx
                services.sing-box
                services.tailscale
                virtualization.incus
                virtualization.podman
                users.sun
              ]);
          }
        )
      ];
    };

  flake.deploy = {
    autoRollback = false;
    magicRollback = false;

    nodes = lib.mapAttrs mkNode self.nixosConfigurations;
  };

  flake.checks = lib.pipe self.nixosConfigurations [
    (lib.filterAttrs (name: cfg: name != "desktop"))
    (lib.mapAttrsToList mkHostCheck)
    (lib.fold lib.recursiveUpdate { })
  ];
}
