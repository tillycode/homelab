{ config, ... }:
let
  domain = config.domains.firefly-iii;
  cfg = config.services.firefly-iii;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.firefly-iii = {
    enable = true;
    enableNginx = true;
    virtualHost = domain;

    settings = {
      SITE_OWNER = "me@szp.io";
      APP_KEY_FILE = config.sops.secrets."firefly-iii/appKey".path;
      TZ = "Asia/Shanghai";
      TRUSTED_PROXIES = "**";
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."firefly-iii/appKey" = {
    owner = cfg.user;
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = cfg.dataDir;
      mode = "0700";
      user = cfg.user;
      group = cfg.group;
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
  };

  ## ---------------------------------------------------------------------------
  ## BACKUP
  ## ---------------------------------------------------------------------------
  services.restic.backups.default.paths = [
    cfg.dataDir
  ];
}
