{ config, ... }:
{
  imports = [
    ./_common.nix
  ];

  services.rke2 = {
    role = "agent";
    serverAddr = "https://${config.domains.k8s}:9345";
    tokenFile = config.sops.secrets."rke2/token".path;
  };

  sops.secrets."rke2/token" = { };
}
