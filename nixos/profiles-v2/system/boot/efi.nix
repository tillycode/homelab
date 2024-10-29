# Description: Use systemd-boot as the boot loader (UEFI)
# Prerequisites:
# 1. EFI partition mounted at `/boot`
#
# TODO: add meta option to collection profile documentation.
{
  boot.loader.timeout = 1;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
}
