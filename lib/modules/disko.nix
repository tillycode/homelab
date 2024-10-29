{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.disko = mkOption {
    description = "Disko profiles";
    type = types.attrsOf types.anything;
    default = { };
  };

  config.suites = lib.mapAttrs' (name: disko: {
    name = "disko.${name}";
    value = {
      profiles = [
        "system.disko"
        { profiles.disko = disko; }
      ];
    };
  }) config.disko;
}
