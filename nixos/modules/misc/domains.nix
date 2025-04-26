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

      tailnet-global = "tailnet.szp.io";

      homepage-dashboard = "home.svc.szp.io";
      incus = "incus.svc.szp.io";
      step-ca = "acme.svc.szp.io";
      acme = config.domains.step-ca;
      terraboard = "terraboard.svc.szp.io";
      oauth2-proxy = "auth.svc.szp.io";
      gha-cache-server = "gha-cache.svc.szp.io";
      minio = "minio.svc.szp.io";
      acme-dns = "acme-dns.svc.szp.io";
      prometheus = "prometheus.svc.szp.io";
      grafana = "grafana.svc.szp.io";
    };
  };
}
