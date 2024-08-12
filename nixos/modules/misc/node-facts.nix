{ lib, ... }:
with lib;
{
  options = {
    misc.node-facts = {
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
        private_ipv4 = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The private IPv4 address of the node.";
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
    };
  };
}
