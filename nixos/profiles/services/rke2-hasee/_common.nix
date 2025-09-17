{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rke2;
  pkg = pkgs.rke2_1_33;
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
      {
        directory = "/var/lib/rook";
        mode = "0700";
      }
      {
        directory = "/var/lib/kubelet";
        mode = "0700";
      }
    ];
  }
  (lib.mkIf (cfg.role == "server") {
    services.rke2 = {
      cni = "none";
      extraFlags = [
        "--disable-kube-proxy"
        "--disable-cloud-controller"
        "--tls-san=${config.domains.k8s}"
        "--tls-san=192.168.22.10"
        # install later
        "--ingress-controller=none"
        "--etcd-arg=listen-metrics-urls=http://0.0.0.0:2381"
        "--kube-scheduler-arg=--bind-address=0.0.0.0"
        "--kube-controller-manager-arg=--bind-address=0.0.0.0"
      ];
    };
  })
  # nix image
  {
    systemd.services.rke2-update-nix-image =
      let
        image = pkgs.dockerTools.streamLayeredImage {
          name = "nix";
          tag = "pinned";
          contents = with pkgs; [
            nix
            bashInteractive
            coreutils-full
            gnutar
            gzip
            gnugrep
            which
            curl
            less
            (dockerTools.override {
              cacert = pkgs.cacert.override {
                extraCertificateFiles = [ ../../../../certs/roots.pem ];
              };
            }).caCertificates
            findutils
            iana-etc
            gitMinimal
            openssh
          ];
          includeStorePaths = false;
        };
      in
      {
        script = ''
          ${image} | /var/lib/rancher/rke2/bin/ctr images import --label io.cri-containerd.pinned=pinned -
        '';
        environment = {
          CONTAINERD_ADDRESS = "/run/k3s/containerd/containerd.sock";
          CONTAINERD_NAMESPACE = "k8s.io";
        };
        after = [ "rke2-${cfg.role}.service" ];
        requires = [ "rke2-${cfg.role}.service" ];
        wantedBy = [ "multi-user.target" ];
      };
  }
]
