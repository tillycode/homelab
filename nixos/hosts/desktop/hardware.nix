let
  mkBtrfsMount = subvol: {
    device = "/dev/disk/by-partlabel/nixos";
    fsType = "btrfs";
    options = [
      "subvol=@${subvol}"
      "noatime"
      "compress-force=zstd"
      "discard=async"
    ];
  };
in
{
  boot.initrd.availableKernelModules = [
    "vmd"
    "xhci_pci"
    "ahci"
    "nvme"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=16G"
      "mode=755"
    ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-partlabel/EFI";
    fsType = "vfat";
  };

  fileSystems."/nix" = mkBtrfsMount "nix";
  fileSystems."/persist" = mkBtrfsMount "persist" // {
    neededForBoot = true;
  };
  fileSystems."/swap" = mkBtrfsMount "swap";

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
  ];

  # sudo btrfs inspect-internal map-swapfile /swap/swapfile
  boot.kernelParams = [ "resume_offset=533760" ];
  boot.resumeDevice = "/dev/disk/by-partlabel/nixos";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
