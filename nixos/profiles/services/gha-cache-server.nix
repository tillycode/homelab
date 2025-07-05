{
  lib,
  pkgs,
  config,
  ...
}:
let
  domain = config.domains.gha-cache-server;
  acmeDomain = config.domains.acme;
  package = pkgs.github-actions-cache-server;
  port = config.ports.gha-cache-server;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  systemd.services.gha-cache-server = {
    enable = true;
    description = "A Self-hosted GitHub Actions cache server implementation";
    wantedBy = [ "multi-user.target" ];

    environment = {
      API_BASE_URL = "https://${domain}";
      NITRO_PORT = toString port;
      NITRO_CLUSTER_WORKERS = "1";
      STORAGE_FILESYSTEM_PATH = "/var/lib/gha-cache-server/storage";
      DB_SQLITE_PATH = "/var/lib/gha-cache-server/db.sqlite";
    };

    serviceConfig = {
      ExecStart = lib.getExe package;
      User = "gha-cache-server";
      Group = "gha-cache-server";
      StateDirectory = "gha-cache-server";
    };
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 600M;
        allow 100.120.0.0/16;
        allow fd7a:115c:a1e0:7::/64;
        allow 10.75.0.0/16;
        allow fd42:e16c:cbc4::/48;
        deny all;
      '';
    };
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };

  ## ---------------------------------------------------------------------------
  ## USERS
  ## ---------------------------------------------------------------------------
  users.users.gha-cache-server = {
    isSystemUser = true;
    home = "/var/lib/gha-cache-server";
    group = "gha-cache-server";
    description = "GitHub Actions Cache Server";
  };
  users.groups.gha-cache-server = { };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/gha-cache-server";
      user = "gha-cache-server";
      group = "gha-cache-server";
      mode = "0700";
    }
  ];
}
