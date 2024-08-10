{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets."k3s/bootstrap-token".path;
    # clusterInit = true;
    gracefulNodeShutdown.enable = true;
    extraFlags = [
      "--node-label"
      "svccontroller.k3s.cattle.io/enablelb=true"
    ];
  };

  sops.secrets."k3s/bootstrap-token" = {
    sopsFile = config.sops-file.common;
  };
}
