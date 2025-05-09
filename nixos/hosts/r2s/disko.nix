{ pkgs, ... }:
let
  device = "/dev/mmcblk0";
  swapSize = "1G";
  tmpfsSize = "50%";
in
{
  # Due to r2s's limited RAM, nixos-anywhere cannot work. As a result, this file only
  # serves as a reference for partitioning. To install NixOS on r2s, you
  # need to
  # 1. format the SD card and mount the filesystems. I plugged the SD card into
  #    my desktop, comment out the `postCreateHook` below, change `device` above to
  #    "/dev/sdX", change `nixpkgs.system` to `x86_64-linux`, and run
  #
  #         nix build .#nixosConfigurations.r2s.config.system.build.diskoScript
  #         sudo ./result
  #
  # 2. install the bootloader. I run
  #
  #         nix build .#packages.aarch64-linux.uboot-nanopi-r2s
  #         sudo dd if=./result/u-boot-rockchip.bin of=/dev/sdX seek=64 conv=notrunc
  #
  # 3. install the system. I revert the ad-hoc changes in step 1, and run
  #
  #         nix build .#nixosConfigurations.r2s.config.system.build.toplevel
  #         sudo nix copy --to /mnt "$(readlink result)"
  #
  # 4. populate boot files. I inspect the `result/bin/switch-to-configuration`,
  #    find the `export INSTALL_BOOTLOADER='/nix/store/...-install-extlinux-conf.sh'`
  #    line, inspect the script, to see the inner script `...-extlinux-conf-builder.sh`,
  #    and run
  #
  #         sudo /nix/store/...-extlinux-conf-builder.sh -g 0 -t 1 -n \
  #             rockchip/rk3328-nanopi-r2s.dtb -d /mnt/boot -c "$(readlink result)"
  #
  # Then the system should boot. I can ssh into the system and further copy
  # nix-store closures to the system via
  # 1. Pointer-to-pointer ethernet. I can discover the IPv6 link-local address
  #    by running `ip n` or use `wireshark`.
  # 2. A full-featured Router.
  disko.devices = {
    disk.nixos = {
      device = device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            # uboot is usually below 10MB
            start = "20M";
            size = "512M";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress-force=zstd"
                    "noatime"
                  ];
                };
                "@persist" = {
                  mountpoint = "/.persist";
                  mountOptions = [ "compress-force=zstd" ];
                };
                "@swap" = {
                  mountpoint = "/.swap";
                  swap = {
                    swapfile.size = swapSize;
                  };
                };
              };
            };
          };
        };
      };
      postCreateHook = ''
        dd if=${pkgs.aarch64-linux.uboot-nanopi-r2s}/u-boot-rockchip.bin of=${device} seek=64 conv=notrunc
      '';
    };

    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=${tmpfsSize}"
          "mode=755"
        ];
      };
    };
  };

  fileSystems."/.persist".neededForBoot = true;
  environment.persistence.default.persistentStoragePath = "/.persist";

  sops.age.sshKeyPaths = [ "/.persist/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];
}
