{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.authorized-keys = mkOption {
    description = "AuthorizedKeys profile";
    type = types.attrsOf types.anything;
    default = { };
  };

  config.suites = lib.mapAttrs' (name: config: {
    name = "authorized-keys.${name}";
    value = {
      profiles = [
        { users.users.root.openssh.authorizedKeys = config; }
      ];
    };
  }) config.authorized-keys;
}
