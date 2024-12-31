{ config, ... }:
let
  loginServer = "https://${config.domains.tailnet}";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.tailscale = {
    enable = true;
    openFirewall = true;

    authKeyFile = config.sops.secrets."tailscale/authkey".path;
    extraUpFlags = [
      "--login-server"
      loginServer
    ];
    extraDaemonFlags = [ "--no-logs-no-support" ];
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."tailscale/authkey" = { };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      # owned by root
      directory = "/var/lib/tailscale";
      mode = "0700";
    }
  ];

  ## TODO:
  ## 1. tailscaled takes a long time to up (seems IPv6 connection is very slow)
}
