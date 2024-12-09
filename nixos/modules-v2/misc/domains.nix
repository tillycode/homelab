{ lib, ... }:
{
  options.domains = lib.mkOption {
    type = with lib.types; attrsOf str;
    default = { };
  };

  config = {
    domains = {
      zitadel = "login.szp15.com";

      netbird = "netbird.szp15.com";
      netbird-overlay = "nodes01.szp.io";

      tailnet = "tailnet.szp15.com";
    };
  };
}
