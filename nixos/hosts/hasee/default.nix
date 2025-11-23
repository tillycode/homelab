{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelParams = [ "intel_iommu=on" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  networking.firewall.enable = false;

  systemd.network.links = {
    "10-eth0" = {
      matchConfig.Path = "pci-0000:03:00.0";
      linkConfig.Name = "eth0";
    };
    "10-wlan0" = {
      matchConfig.Path = "pci-0000:04:00.0";
      linkConfig.Name = "wlan0";
    };
  };

  systemd.network.networks = {
    "40-eth0" = {
      matchConfig.Name = "eth0";
      DHCP = "ipv4";
      networkConfig.IPv6AcceptRA = false;
    };
    "40-wlan0" = {
      matchConfig.Name = "wlan0";
      linkConfig.Unmanaged = true;
    };
  };

  users.users.root.hashedPassword = "$y$j9T$5H0k9lXNhiB/RWu34ZqmR/$tS3OgHLomQFWEeP515WYo8AFKYjIw0gG.BZurM6FMR8";
  systemd.network.netdevs = {
    "40-bond0" = {
      netdevConfig = {
        Name = "bond0";
        Kind = "bond";
      };
      bondConfig = {
        Mode = "active-backup";
        MIIMonitorSec = "100ms";
      };
    };
  };
  systemd.network.networks = {
    "50-bond-slave" = {
      matchConfig.Path = "pci-0000:00:14.0-usb-0:*:1.0";
      linkConfig.MTUBytes = 9000;
      networkConfig = {
        Bond = "bond0";
        DHCP = "no";
        IPv6PrivacyExtensions = "kernel";
      };
    };
    "40-bond0" = {
      matchConfig.Name = "bond0";
      linkConfig.MTUBytes = 9000;
      gateway = [ "10.9.0.1" ];
      dns = [ "10.9.0.1" ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };
    };
  };
}
