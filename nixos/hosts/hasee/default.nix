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
}
