{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  node-key = {
    options = {
      ssh-keys = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      age-key = mkOption {
        type = types.str;
      };
    };
  };
in
{
  options.node-keys = mkOption {
    description = "Node keys";
    type = types.attrsOf (types.submodule node-key);
    default = { };
  };
  config = {
    nodes = lib.mapAttrs (node: _: {
      profiles = [
        {
          sops.defaultSopsFile = ../secrets/nodes/${node}.yaml;
        }
      ];
    }) config.node-keys;
  };
}
