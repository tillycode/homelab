{ config, ... }:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.atticd = {
    enable = true;
    settings = {
      listen = "[::1]:${toString config.ports.atticd}";
      allowed-hosts = [ config.domains.atticd ];
      api-endpoint = "https://${config.domains.atticd}/";
      storage = {
        type = "s3";
        region = "";
        bucket = "cache";
        endpoint = "https://szpio-atticd-storage.oss-cn-hangzhou.aliyuncs.com";
      };
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "1 month";
      };
    };
    environmentFile = config.sops.templates."atticd-secrets.env".path;
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."atticd/tokenRS256Secret" = { };
  sops.secrets."atticd/ossAccessKeyId" = { };
  sops.secrets."atticd/ossAccessKeySecret" = { };

  sops.templates."atticd-secrets.env" = {
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd/tokenRS256Secret"}
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."atticd/ossAccessKeyId"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."atticd/ossAccessKeySecret"}
    '';
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/atticd";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${config.domains.atticd} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.atticd}";
      extraConfig = ''
        allow 100.71.0.0/16;
        allow fd7a:115c:a1e0:7::/64;
        allow 10.75.0.0/16;
        allow fd42:e16c:cbc4::/48;
        client_max_body_size 100M;
        deny all;
      '';
    };
  };
  security.acme.certs."${config.domains.atticd}" = {
    server = "https://${config.domains.acme}/acme/acme/directory";
  };
}
