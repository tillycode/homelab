{ config, ... }:
let
  domain = config.domains.loki;
  acmeDomain = config.domains.acme;
  port = config.ports.loki;
  portGrpc = config.ports.loki-grpc;
  cfg = config.services.loki;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "::1";
        http_listen_port = port;
        grpc_listen_address = "::1";
        grpc_listen_port = portGrpc;
      };
      # Loki UI is available in 3.5.0 and later
      common = {
        instance_addr = "::1";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
          cache_location = "/var/lib/loki/index-cache";
        };
        alibabacloud = {
          bucket = "szpio-loki-data";
          access_key_id = "\${OSS_ACCESS_KEY_ID}";
          secret_access_key = "\${OSS_ACCESS_KEY_SECRET}";
          endpoint = "oss-cn-hangzhou-internal.aliyuncs.com";
        };
      };
      query_range.results_cache.cache.embedded_cache = {
        enabled = true;
        max_size_mb = 100;
      };
      limits_config = {
        retention_period = "30d";
        metric_aggregation_enabled = true;
        deletion_mode = "filter-and-delete";
      };
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "tsdb";
          object_store = "alibabacloud";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      pattern_ingester = {
        enabled = true;
        metric_aggregation = {
          loki_address = "[::1]:${toString port}";
        };
      };
      frontend.encoding = "protobuf";
      analytics.reporting_enabled = false;
    };
    extraFlags = [
      "--config.expand-env=true"
    ];
  };
  systemd.services.loki.serviceConfig.EnvironmentFile = config.sops.templates."loki.env".path;

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/loki";
      mode = "0700";
      user = cfg.user;
      group = cfg.group;
    }
  ];

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
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."loki/ossAccessKeyId" = { };
  sops.secrets."loki/ossAccessKeySecret" = { };
  sops.templates."loki.env" = {
    content = ''
      OSS_ACCESS_KEY_ID=${config.sops.placeholder."loki/ossAccessKeyId"}
      OSS_ACCESS_KEY_SECRET=${config.sops.placeholder."loki/ossAccessKeySecret"}
    '';
  };
}
