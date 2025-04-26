{ config, ... }:
let
  domain = config.domains.prometheus;
  acmeDomain = config.domains.acme;
  port = config.ports.prometheus;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.prometheus = {
    enable = true;
    port = port;
    listenAddress = "[::1]";
    webExternalUrl = "https://${domain}/";
    retentionTime = "30d";
    globalConfig = {
      scrape_interval = "1m";
      evaluation_interval = "1m";
      scrape_timeout = "10s";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "desktop.ts.szp.io:${toString config.ports.node-exporter}"
              "hgh2.ts.szp.io:${toString config.ports.node-exporter}"
              "sha0.ts.szp.io:${toString config.ports.node-exporter}"
            ];
          }
        ];
      }
      {
        job_name = "coredns";
        static_configs = [
          { targets = [ "100.71.0.1:${toString config.ports.coredns-metrics}" ]; }
        ];
      }
      {
        job_name = "headscale";
        static_configs = [
          { targets = [ "100.71.0.1:${toString config.ports.headscale-metrics}" ]; }
        ];
      }
      {
        job_name = "zitadel";
        scheme = "https";
        metrics_path = "/debug/metrics";
        static_configs = [ { targets = [ config.domains.zitadel ]; } ];
      }
      {
        job_name = "incus";
        scheme = "https";
        metrics_path = "/1.0/metrics";
        static_configs = [
          { targets = [ config.domains.incus ]; }
        ];
      }
      {
        job_name = "step-ca";
        static_configs = [
          {
            targets = [ "${config.domains.step-ca}:${toString config.ports.step-ca-metrics}" ];
          }
        ];
      }
      {
        job_name = "minio";
        scheme = "https";
        metrics_path = "/minio/v2/metrics/cluster";
        static_configs = [ { targets = [ config.domains.minio ]; } ];
      }
      {
        job_name = "prometheus";
        scheme = "https";
        static_configs = [ { targets = [ config.domains.prometheus ]; } ];
      }
    ];
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
    };
    extraConfig = ''
      allow 100.71.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/${config.services.prometheus.stateDir}";
      mode = "0700";
      user = "prometheus";
      group = "prometheus";
    }
  ];
}
