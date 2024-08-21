{ lib, pkgs, ... }:
let
  audit-yaml = pkgs.writeText "audit.yaml" ''
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    - level: Metadata
  '';
in
{
  config = lib.mkMerge [
    {
      services.k3s = {
        role = "server";
        extraFlags = [
          "--node-label"
          "svccontroller.k3s.cattle.io/enablelb=true"
        ];
      };

    }
    # audit log
    {
      services.k3s.extraFlags = [
        "--kube-apiserver-arg=audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log"
        "--kube-apiserver-arg=audit-policy-file=/var/lib/rancher/k3s/server/audit.yaml"
      ];
      systemd.tmpfiles.rules = [
        "d /var/lib/rancher/k3s/server/logs 0700 root root -"
        "L+ /var/lib/rancher/k3s/server/audit.yaml 0600 root root - ${audit-yaml}"
      ];
      systemd.services.k3s = {
        after = [ "systemd-tmpfiles-setup.service" ];
      };
    }
  ];
}
