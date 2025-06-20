{
  config,
  lib,
  ...
}:
let
  cfg = config.services.rke2;
in
lib.mkMerge [
  {
    services.rke2 = {
      enable = true;
      cisHardening = true;
      nodeInterface = "tailscale0";
      useResolved = true;
    };

    # for cilium
    networking.firewall.checkReversePath = "loose";
    networking.firewall.trustedInterfaces = [
      "cilium*"
      "lxc*"
    ];

    environment.persistence.default.directories = [
      cfg.dataDir
    ];
  }
  (lib.mkIf (cfg.role == "server") {
    services.rke2 = {
      cni = "cilium";
      extraFlags = [
        "--disable-kube-proxy"
        "--disable-cloud-controller"
        "--tls-san=${config.domains.k8s}"
        "--ingress-controller=traefik"
      ];
    };
  })
]
