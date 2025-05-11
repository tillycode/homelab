{
  config,
  pkgs,
  lib,
  ...
}:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_15;
  services.postgresql.authentication = lib.mkForce ''
    # TYPE   DATABASE   USER   ADDRESS        METHOD
    local    all        all                   peer
    host     all        all    127.0.0.1/32   scram-sha-256
    host     all        all    ::1/128        scram-sha-256
  '';

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = config.services.postgresql.dataDir;
      user = "postgres";
      group = "postgres";
      mode = "0750";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## BACKUP
  ## ---------------------------------------------------------------------------
  services.restic.backups.default.paths = [
    "/var/lib/postgresql"
  ];
}
