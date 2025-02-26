{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];
  boot.kernelParams = [ "resume_offset=533760" ];
  boot.resumeDevice = "/dev/disk/by-partlabel/disk-root-root";

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

  environment.persistence.default.directories = [
    "/var/lib/systemd/backlight"
  ];
}
