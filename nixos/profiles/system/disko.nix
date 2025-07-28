{ lib, config, ... }:
with lib;
let
  cfg = config.profiles.disko;
in
{
  options.profiles.disko = {
    device = mkOption {
      type = types.str;
      description = "Full path to the device, e.g. `/dev/vda`";
    };
    swapSize = mkOption {
      type = types.nullOr types.str;
      description = ''
        The size of the swap file

        The swap file will be created using `btrfs filesystem mkswap --size $SIZE`.
        It accepts suffix like `G` for 1024-based units.
        Set to `null` to disable swap.
      '';
    };
    tmpfsSize = mkOption {
      type = types.str;
      description = ''
        The size limit of the root tmpfs.

        This is the mount option `size` of the tmpfs.
        It accepts suffix like `G` for 1024-based units and `%` for percentage of RAM.
      '';
      default = "50%";
    };
  };
  config = {
    disko.devices = {
      disk.root = {
        device = cfg.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              name = "ESP";
              size = "128M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
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
                }
                // lib.optionalAttrs (cfg.swapSize != null) {
                  "@swap" = {
                    mountpoint = "/.swap";
                    swap = {
                      swapfile.size = cfg.swapSize;
                    };
                  };
                };
              };
            };
          };
        };
      };
      nodev = {
        "/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=${cfg.tmpfsSize}"
            "mode=755"
          ];
        };
      };
    };

    fileSystems."/.persist".neededForBoot = true;
    environment.persistence.default.persistentStoragePath = "/.persist";

    sops.age.sshKeyPaths = [ "/.persist/etc/ssh/ssh_host_ed25519_key" ];
    sops.gnupg.sshKeyPaths = [ ];
  };
}
