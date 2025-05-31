{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rke2;
  # https://nixpk.gs/pr-tracker.html?pr=405952
  rke2-util-linux = pkgs.util-linux.overrideAttrs (prev: {
    patches =
      prev.patches or [ ]
      ++ lib.singleton (
        pkgs.fetchpatch {
          url = "https://github.com/util-linux/util-linux/pull/3479.patch";
          hash = "sha256-bJqpZiPli5Pm/XpDA445Ab5jesXrlcnaO6e4V0B3rSw=";
        }
      );
  });

in
lib.mkMerge [
  {
    services.rke2 = {
      enable = true;
      package = pkgs.rke2.override {
        util-linux = rke2-util-linux;
      };
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
      ];
    };
  })
]
