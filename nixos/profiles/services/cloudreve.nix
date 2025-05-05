{
  config,
  pkgs,
  lib,
  ...
}:
let
  ## ---------------------------------------------------------------------------
  ## SETTINGS
  ## ---------------------------------------------------------------------------
  package = pkgs.cloudreve;
  stateDir = "/var/lib/cloudreve";
  settings = lib.generators.toINI { } {
    System = {
      Debug = false;
      Mode = "master";
      Listen = "[::1]:${toString config.ports.cloudreve}";
      SessionSecret = config.sops.placeholder."cloudreve/sessionSecret";
      HashIDSalt = config.sops.placeholder."cloudreve/hashIdSalt";
      ProxyHeader = "X-Forwarded-For";
    };
    Database = {
      Type = "sqlite";
      DBFile = "${stateDir}/cloudreve.db";
    };
  };
in
{
  ## ---------------------------------------------------------------------------
  ## SERVICE
  ## ---------------------------------------------------------------------------
  systemd.services.cloudreve = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = [
        "${lib.getExe package} server -c ${config.sops.templates."cloudreve.ini".path} -w ${stateDir}"
      ];
      StateDirectory = "cloudreve";
      User = "cloudreve";
      Group = "cloudreve";
      WorkingDirectory = stateDir;
      Restart = "on-abnormal";
      RestartSec = "5s";
      KillMode = "mixed";
    };
  };

  users.users.cloudreve = {
    isSystemUser = true;
    group = "cloudreve";
    extraGroups = [ "aria2" ];
    home = stateDir;
  };
  users.groups.cloudreve = { };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."cloudreve/sessionSecret" = { };
  sops.secrets."cloudreve/hashIdSalt" = { };
  sops.templates."cloudreve.ini" = {
    content = settings;
    owner = "cloudreve";
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${config.domains.cloudreve} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.cloudreve}";
    };
    extraConfig = ''
      client_max_body_size 5G;
    '';
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/cloudreve";
      mode = "0700";
    }
  ];
}
