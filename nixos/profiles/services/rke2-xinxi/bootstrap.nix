{ pkgs, ... }:
let
  pkg = pkgs.rke2_1_34;
in
{
  services.rke2 = {
    enable = true;
    package = pkg;
    images = [
      pkg.images-core-linux-amd64-tar-zst
    ];
    cisHardening = true;
    role = "server";
    cni = "none";
    extraFlags = [
      "--disable-kube-proxy"
      "--disable-cloud-controller"
      "--ingress-controller=none"
      "--disable=rke2-coredns,rke2-metrics-server,rke2-snapshot-controller,rke2-snapshot-controller-crd,rke2-snapshot-validation-webhook"
      # for multiple clusters
      "--cluster-cidr=10.10.0.0/16"
      "--service-cidr=10.11.0.0/16"
      "--cluster-domain=rke2-xinxi.local"
      # TODO: domain and IP for k8s
      # "--tls-san=${config.domains.k8s}"
      "--node-ip=10.9.0.13"
    ];
  };

  environment.persistence.default.directories = [
    "/var/lib/rancher"
    {
      directory = "/var/lib/kubelet";
      mode = "0750";
    }
    {
      directory = "/run/k3s";
      mode = "0711";
    }
  ];

  home-manager.users.root = {
    home.stateVersion = "25.05";
    home.sessionPath = [
      "/var/lib/rancher/rke2/bin"
    ];
    home.sessionVariables = {
      KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
      CRI_CONFIG_FILE = "/var/lib/rancher/rke2/agent/etc/crictl.yaml";
      CONTAINERD_ADDRESS = "/run/k3s/containerd/containerd.sock";
      CONTAINERD_NAMESPACE = "k8s.io";
    };
    home.packages = with pkgs; [
      k9s
    ];
    programs.bash = {
      enable = true;
      shellAliases = {
        etcdctl = ''
          crictl exec "$(crictl ps --label io.kubernetes.container.name=etcd --quiet)" etcdctl \
            --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt \
            --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key \
            --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt \
        '';
      };
    };
  };
}
