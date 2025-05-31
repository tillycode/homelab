{ config, ... }:
{
  imports = [
    ./_rke2-common.nix
  ];

  services.rke2 = {
    role = "server";
    manifests = {
      "rke2-ingress-nginx-config.yaml" = ''
        apiVersion: helm.cattle.io/v1
        kind: HelmChartConfig
        metadata:
          name: rke2-ingress-nginx
          namespace: kube-system
        spec:
          valuesContent: |
            controller:
              hostPort:
                ports:
                  http: ${toString config.ports.rke2-ingress-http}
                  https: ${toString config.ports.rke2-ingress-https}
              config:
                use-forwarded-headers: "true"
      '';
      "rke2-cilium-config.yaml" = ''
        apiVersion: helm.cattle.io/v1
        kind: HelmChartConfig
        metadata:
          name: rke2-cilium
          namespace: kube-system
        spec:
          valuesContent: |
            kubeProxyReplacement: true
            k8sServiceHost: "localhost"
            k8sServicePort: "6443"
            MTU: 1280
            localRedirectPolicy: true
            operator:
              replicas: 1
            hubble:
              enabled: true
              relay:
                enabled: true
              ui:
                enabled: true
      '';
      "rke2-coredns-config.yaml" = ''
        apiVersion: helm.cattle.io/v1
        kind: HelmChartConfig
        metadata:
          name: rke2-coredns
          namespace: kube-system
        spec:
          valuesContent: |
            nodelocal:
              enabled: true
              use_cilium_lrp: true
      '';
      "node-local-dns-network-policy.yaml" = ''
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: node-local-dns-policy
          namespace: kube-system
        spec:
          podSelector:
            matchLabels:
              k8s-app: node-local-dns
          policyTypes:
          - Ingress
          ingress:
          - ports:
            - protocol: UDP
              port: 53
            - protocol: TCP
              port: 53
      '';
    };
  };
}
