{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://hgh2:6443";
    tokenFile = config.sops.secrets."k3s/bootstrap-token".path;
    gracefulNodeShutdown.enable = true;
  };

  sops.secrets."k3s/bootstrap-token" = {
    sopsFile = config.sops-file.common;
  };

  environment.persistence."/persist" = {
    directories = [ "/etc/rancher" ];
  };
}
