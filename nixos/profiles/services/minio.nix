{ config, pkgs, ... }:
let
  domain = config.domains.minio;
  acmeDomain = config.domains.acme;
  port = config.ports.minio;
  consolePort = config.ports.minio-console;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.minio = {
    enable = true;
    listenAddress = "[::1]:${toString port}";
    consoleAddress = "[::1]:${toString consolePort}";
    rootCredentialsFile = config.sops.templates."minio/rootCredentials.env".path;
  };
  systemd.services.minio = {
    environment = {
      MINIO_DOMAIN = config.domains.minio;
      MINIO_COMPRESSION_ENABLED = "on";
      MINIO_BROWSER_REDIRECT_URL = "https://${config.domains.minio}/console";
      CONSOLE_SUBPATH = "console";

      MINIO_IDENTITY_OPENID_CONFIG_URL = "https://login.szp15.com/.well-known/openid-configuration";
      MINIO_IDENTITY_OPENID_CLAIM_NAME = "groups";
      MINIO_IDENTITY_OPENID_DISPLAY_NAME = "SSO (login.szp15.com)";

      MINIO_PROMETHEUS_AUTH_TYPE = "public";
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."minio/rootUser" = { };
  sops.secrets."minio/rootPassword" = { };
  sops.secrets."minio/clientId" = { };
  sops.secrets."minio/clientSecret" = { };
  sops.secrets."minio/acmeDnsAccount/username" = { };
  sops.secrets."minio/acmeDnsAccount/password" = { };
  sops.templates."minio/rootCredentials.env" = {
    content = ''
      MINIO_ROOT_USER=${config.sops.placeholder."minio/rootUser"}
      MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/rootPassword"}
      MINIO_IDENTITY_OPENID_CLIENT_ID=${config.sops.placeholder."minio/clientId"}
      MINIO_IDENTITY_OPENID_CLIENT_SECRET=${config.sops.placeholder."minio/clientSecret"}
    '';
  };
  sops.templates."minio/acmeDnsAccount.json" = {
    # TODO: sync subdomain to coredns.nix
    content = ''
      {
        "${domain}": {
          "username": "${config.sops.placeholder."minio/acmeDnsAccount/username"}",
          "password": "${config.sops.placeholder."minio/acmeDnsAccount/password"}",
          "subdomain": "47f2e892-8271-443a-a9c7-43c14873b066"
        }
      }
    '';
    owner = "acme";
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/minio";
      user = "minio";
      group = "minio";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    serverAliases = [ "*.${domain}" ];

    locations."/console" = {
      proxyPass = "http://[::1]:${toString consolePort}";
      proxyWebsockets = true;
      extraConfig = ''
        rewrite ^/console/(.*) /$1 break;
      '';
    };
    locations."= /console" = {
      return = "301 /console/";
    };

    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };

    extraConfig = ''
      client_max_body_size 600M;
      allow 100.71.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs."${domain}" = {
    webroot = null;
    server = "https://${acmeDomain}/acme/acme/directory";
    dnsProvider = "acme-dns";
    environmentFile = pkgs.writeText "lego.env" ''
      ACME_DNS_API_BASE=https://${config.domains.acme-dns}
      ACME_DNS_STORAGE_PATH=${config.sops.templates."minio/acmeDnsAccount.json".path}
    '';
  };
}
