{ config, lib, ... }:
{
  options.domains = lib.mkOption {
    type = with lib.types; lazyAttrsOf str;
    default = { };
  };

  config = {
    domains = {
      zitadel = "login.szp15.com";
      netbird = "netbird.szp15.com";
      tailnet = "tailnet.szp15.com";
      atticd = "cache.szp15.com";

      homepage-dashboard = "home.svc.szp.io";
      incus = "incus.svc.szp.io";
      step-ca = "acme.svc.szp.io";
      acme = config.domains.step-ca;
    };
  };
}
