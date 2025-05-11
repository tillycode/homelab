{ config, lib, ... }:
{
  options.domains = lib.mkOption {
    type = with lib.types; lazyAttrsOf str;
    default = { };
  };

  config = {
    domains = {
      ## -----------------------------------------------------------------------
      ## PUBLIC DOMAINS
      ## -----------------------------------------------------------------------

      # domestic domains
      zitadel = "login.szp15.com";
      netbird = "netbird.szp15.com"; # unused
      atticd = "cache.szp15.com";
      firefly-iii = "firefly.szp15.com";
      tailnet = "tailnet.szp15.com";
      cloudreve = "file.szp15.com";
      cloudreve-cname = "downloads.szp15.com";
      blog = "szp15.com";
      xray = "${config.networking.hostName}.szp15.com";

      # global domains
      tailnet-global = "tailnet.szp.io";
      xray-global = "${config.networking.hostName}.eh578599.xyz";

      # well-known public domains
      sso = config.domains.zitadel;

      ## -----------------------------------------------------------------------
      ## PRIVATE DOMAINS
      ## -----------------------------------------------------------------------

      # base domains
      base-tailnet = "ts.szp.io";
      base-tailnet-global = "tsg.szp.io";
      base-incus = "vm.szp.io";
      base-service = "svc.szp.io";

      # service domains
      homepage-dashboard = "home.svc.szp.io";
      incus = "incus.svc.szp.io";
      step-ca = "acme.svc.szp.io";
      terraboard = "terraboard.svc.szp.io"; # unused
      oauth2-proxy = "auth.svc.szp.io"; # unused
      gha-cache-server = "gha-cache.svc.szp.io";
      minio = "minio.svc.szp.io";
      acme-dns = "acme-dns.svc.szp.io";
      prometheus = "prometheus.svc.szp.io";
      grafana = "grafana.svc.szp.io";
      loki = "loki.svc.szp.io";

      # well-known private domains
      acme = config.domains.step-ca;
    };
  };
}
