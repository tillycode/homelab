{
  pkgs,
  lib,
  ...
}:
let
  linux-firmware-r8152 = pkgs.fetchurl {
    url = "https://github.com/friendlyarm/sd-fuse_rk3328/raw/refs/heads/kernel-6.1.y/prebuilt/firmware/files/usr/lib/firmware/rtl_nic/rtl8153b-2.fw";
    sha256 = "sha256-jpRM6G4r4MCuZwmW9jMCqa42OUuvLVudL++ySGULpuA=";
  };
in
{
  imports = [
    ./disko.nix
  ];
  hardware.deviceTree.name = "rockchip/rk3328-nanopi-r2s.dtb";

  hardware.firmware = [
    (pkgs.runCommand "linux-firmware-r8152" { } ''
      install -TDm644 ${linux-firmware-r8152} $out/lib/firmware/rtl_nic/rtl8153b-2.fw
    '')
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "console=ttyS2,1500000"
    "earlycon=uart8250,mmio32,0xff130000"
    "mitigations=off"
  ];
  boot.blacklistedKernelModules = [
    "hantro_vpu"
    "drm"
    "lima"
    "rockchip_vdec"
  ];
  boot.supportedFilesystems.zfs = lib.mkForce false;

  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = [ "mmc_block" ];

  powerManagement.cpuFreqGovernor = "schedutil";
}
