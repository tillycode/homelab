{ config, ... }:
{
  imports = [
    ./_rke2-common.nix
  ];

  services.rke2 = {
    role = "server";
    serverAddr = "https://${config.domains.k8s}:9345";
    tokenFile = config.sops.secrets."rke2/token".path;
  };

  sops.secrets."rke2/token" = { };
}
