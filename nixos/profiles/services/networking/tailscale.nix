{ config, ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-cn/authkey".path;
    extraUpFlags = [
      "--login-server"
      "https://headscale.szp15.com"
    ];
    extraDaemonFlags = [ "--no-logs-no-support" ];
  };

  # Provision steps on headscale.szp15.com
  # 1. headscale user create ziping-sun
  # 2. headscale preauthkeys create --reusable -u ziping-sun -e 30d
  sops.secrets."tailscale-cn/authkey" = {
    sopsFile = config.sops-file.common;
  };
}
