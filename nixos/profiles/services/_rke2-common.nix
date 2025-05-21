{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rke2;
  cisHardening = true;
  generateYaml = (pkgs.formats.yaml { }).generate;
  rke2-ingress-nginx-config = generateYaml "rke2-ingress-nginx-config.yaml" {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChartConfig";
    metadata = {
      name = "rke2-ingress-nginx";
      namespace = "kube-system";
    };
    spec = {
      valuesContent = ''
        controller:
          hostPort:
           ports:
             http: ${toString config.ports.rke2-ingress-http}
             https: ${toString config.ports.rke2-ingress-https}
          config:
            use-forwarded-headers: "true"
      '';
    };
  };

in
lib.mkMerge [
  {
    services.rke2 = {
      enable = true;
      cni = "canal";
      extraFlags = [
        "--kube-proxy-arg"
        "--proxy-mode=ipvs"
      ];
    };

    networking.firewall.trustedInterfaces = [ "cali*" ];

    systemd.tmpfiles.rules = [
      "L+ ${cfg.dataDir}/server/manifests/rke2-ingress-nginx-config.yaml - - - - ${rke2-ingress-nginx-config}"
    ];

  }
  ## ---------------------------------------------------------------------------
  ## SECURITY
  ## ---------------------------------------------------------------------------
  (lib.mkIf cisHardening {
    # See: https://docs.rke2.io/security/hardening_guide#set-kernel-parameters
    boot.kernel.sysctl = lib.mkIf cfg.cisHardening {
      "vm.panic_on_oom" = 0;
      "vm.overcommit_memory" = 1;
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
    };

    services.rke2.extraFlags = [
      "--profile=cis"
    ];
  })
  (lib.mkIf (cisHardening && cfg.role == "server") {
    users.users.etcd = {
      isSystemUser = true;
      group = "etcd";
    };
    users.groups.etcd = { };
  })
]
