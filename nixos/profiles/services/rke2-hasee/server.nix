{ config, ... }:
{
  imports = [
    ./_common.nix
  ];
  services.rke2 = {
    role = "server";
    serverAddr = "https://192.168.22.10:9345";
    tokenFile = config.sops.secrets."rke2-hasee/token".path;
  };

  sops.secrets."rke2-hasee/token" = { };
}
