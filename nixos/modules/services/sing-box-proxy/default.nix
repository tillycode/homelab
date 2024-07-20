{ lib, pkgs, ... }:
let
  json = pkgs.formats.json;
in
{
  options = {
    services.proxy = {
      enable = lib.mkEnableOption "Enable sing-box proxy service";
      enableClashMode = lib.mkEnableOption "Enable clash mode";
      dnsBlockRules = lib.mkOption {
        type = lib.types.listOf json.type;
        default = [ ];
      };
      dnsLocalRules = lib.mkOption {
        type = lib.types.listOf json.type;
        default = [ ];
      };
    };
  };
}
