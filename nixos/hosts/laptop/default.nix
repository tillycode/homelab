{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];
  boot.kernelParams = [ "resume_offset=533760" ];
  boot.resumeDevice = "/dev/disk/by-partlabel/disk-vda-root";

  # TODO: add personal profiles to avoid the hard code
  # sudo mkfs.vfat -C -F 32 civ6mods.img 2097152
  # lsblk
  # sudo losetup /dev/loop28 civ6mods.img
  # sudo mount -o uid=<user>,gid=users,fmask=113,dmask=002,iocharset=iso8859-1 /dev/loop28 "/home/<username>/.local/share/Steam/steamapps/workshop/content/"
  fileSystems."/home/sun/.local/share/Steam/steamapps/workshop/content" = {
    device = "/home/sun/.local/share/Steam/steamapps/workshop/content.img";
    fsType = "vfat";
    options = [
      "loop"
      "uid=sun"
      "gid=users"
      "fmask=133"
      "dmask=022"
      "iocharset=iso8859-1"
      "nofail"
    ];
  };

  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];

  nixpkgs.overlays = [
    (self: super: {
      linux-firmware = super.linux-firmware.overrideAttrs (
        oldAttrs:
        assert self.lib.assertOneOf "old linux-firmware version" oldAttrs.version [
          "20250311"
        ];
        rec {
          version = "20250211";

          src = self.fetchzip {
            url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/linux-firmware-${version}.tar.gz";
            hash = "sha256-ZEXCMz789MtJLBjf4PjUJygURbZVV1XNZoG+5QHpHCQ=";
          };
        }
      );
    })
  ];
}
