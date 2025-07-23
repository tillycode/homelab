{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rke2;
  pkg = pkgs.rke2_1_32;
in
lib.mkMerge [
  {
    services.rke2 = {
      enable = true;
      cisHardening = true;
      useResolved = true;
      package = pkg;
    };

    environment.persistence.default.directories = [
      cfg.dataDir
      {
        directory = "/run/k3s";
        mode = "0711";
      }
    ];
  }
  (lib.mkIf (cfg.role == "server") {
    services.rke2 = {
      cni = "cilium";
      extraFlags = [
        "--disable-kube-proxy"
        "--disable-cloud-controller"
        "--tls-san=${config.domains.k8s}"
        "--tls-san=192.168.22.10"
        "--ingress-controller=traefik"
      ];
    };
  })
]
