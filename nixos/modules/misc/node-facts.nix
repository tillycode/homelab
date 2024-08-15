{ lib, ... }:
with lib;
{
  options.misc.node-facts = {
    addresses = {
      public_ipv4 = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The public IPv4 address of the node.";
      };
      public_ipv6 = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The public IPv6 address of the node.";
      };
      overlay_ipv4 = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The overlay IPv4 address of the node.";
      };
      overlay_ipv6 = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The overlay IPv6 address of the node.";
      };
    };
    resources = {
      disks = lib.mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = lib.mkOption {
                type = types.str;
                description = "The name of the disk.";
              };
              size = lib.mkOption {
                type = types.int;
                description = "The size of the disk in GiB.";
              };
            };
          }
        );
        default = [ ];
        description = "The disks of the node.";
      };
    };
  };
}
