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
      tailnet = "tailnet.szp15.com";

      lxd = "lxd.svc.szp.io";
      ca = "ca.svc.szp.io";
    };
  };
}
