{ config, ... }:
{
  ## ---------------------------------------------------------------------------
  ## SETTINGS
  ## ---------------------------------------------------------------------------
  services.aria2 = {
    enable = true;
    rpcSecretFile = config.sops.secrets."aria2/rpcSecret".path;
    serviceUMask = "0002";
    settings = {
      continue = true;
      save-session-interval = 60;
      rpc-listen-port = config.ports.aria2-rpc;
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/aria2";
      mode = "0770";
      user = "aria2";
      group = "aria2";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."aria2/rpcSecret" = { };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall = {
    allowedUDPPortRanges = config.services.aria2.settings.listen-port;
  };
}
