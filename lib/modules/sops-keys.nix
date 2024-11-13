{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.sops-keys = mkOption {
    description = "SOPS keys";
    type = types.attrsOf (types.anything);
    default = { };
  };
}
