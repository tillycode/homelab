{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.rke2;
  local-dns-ip = config.IPs.local-dns;
in
{
  options.services.rke2 = {
    nodeInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Set --node-ip from interface.";
    };
    enableNodeInterfaceIPv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable --node-ip from interface for IPv6.";
    };
    manifests = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
      default = { };
      description = "Additional manifests to apply.";
    };
    useResolved = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use systemd-resolved for DNS resolution.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable == true && cfg.nodeInterface != null) {
      systemd.services."rke2-${cfg.role}" = {
        serviceConfig = {
          ExecStartPre = [
            (pkgs.writeShellScript "wait-for-netdev" ''
              until [[ -n "$(${pkgs.iproute2}/bin/ip -br address show up scope global dev ${lib.escapeShellArg cfg.nodeInterface} 2>/dev/null)" ]]; do
                sleep 1
              done
            '')
          ];
          ExecStart = lib.mkForce (
            pkgs.writeShellScript "rke2-${cfg.role}-start" ''
              set -euo pipefail
              readarray -d "" node_ips < <(
                ${pkgs.iproute2}/bin/ip -j address show up scope global dev ${lib.escapeShellArg cfg.nodeInterface} |
                ${pkgs.jq}/bin/jq --raw-output0 ${
                  lib.escapeShellArg (
                    if cfg.enableNodeInterfaceIPv6 then
                      ".[].addr_info[].local | select(.)"
                    else
                      ".[].addr_info[] | select(.family == \"inet\") | .local"
                  )
                }
              )
              set -x
              exec ${cfg.package}/bin/rke2 ${
                lib.escapeShellArgs (
                  (lib.singleton cfg.role)
                  ++ (lib.optional (cfg.configPath != "/etc/rancher/rke2/config.yaml") "--config=${cfg.configPath}")
                  ++ (lib.optional cfg.debug "--debug")
                  ++ (lib.optional (cfg.dataDir != "/var/lib/rancher/rke2") "--data-dir=${cfg.dataDir}")
                  ++ (lib.optional (cfg.token != "") "--token=${cfg.token}")
                  ++ (lib.optional (cfg.tokenFile != null) "--token-file=${cfg.tokenFile}")
                  ++ (lib.optionals (cfg.role == "server" && cfg.disable != [ ]) (
                    map (d: "--disable=${d}") cfg.disable
                  ))
                  ++ (lib.optional (cfg.nodeName != null) "--node-name=${cfg.nodeName}")
                  ++ (lib.optionals (cfg.nodeLabel != [ ]) (map (l: "--node-label=${l}") cfg.nodeLabel))
                  ++ (lib.optionals (cfg.nodeTaint != [ ]) (map (t: "--node-taint=${t}") cfg.nodeTaint))
                  ++ (lib.optional (cfg.nodeIP != null) "--node-ip=${cfg.nodeIP}")
                  ++ (lib.optional (cfg.role == "server" && cfg.agentToken != "") "--agent-token=${cfg.agentToken}")
                  ++ (lib.optional (
                    cfg.role == "server" && cfg.agentTokenFile != null
                  ) "--agent-token-file=${cfg.agentTokenFile}")
                  ++ (lib.optional (cfg.serverAddr != "") "--server=${cfg.serverAddr}")
                  ++ (lib.optional cfg.selinux "--selinux")
                  ++ (lib.optional (cfg.role == "server" && cfg.cni != "canal") "--cni=${cfg.cni}")
                  ++ (lib.optional cfg.cisHardening "--profile=${
                    if cfg.package.version >= "1.27" then
                      "cis"
                    else if cfg.package.version >= "1.25" then
                      "cis-1.23"
                    else
                      "cis-1.6"
                  }")
                  ++ cfg.extraFlags
                )
              } "''${node_ips[@]/#/--node-ip=}"
            ''
          );
        };
      };
    })
    (lib.mkIf (cfg.enable == true && cfg.nodeInterface == null) {
      systemd.services."rke2-${cfg.role}".serviceConfig.ExecStart =
        lib.mkForce "${cfg.package}/bin/rke2 '${cfg.role}' ${
          lib.escapeShellArgs (
            (lib.optional (cfg.configPath != "/etc/rancher/rke2/config.yaml") "--config=${cfg.configPath}")
            ++ (lib.optional cfg.debug "--debug")
            ++ (lib.optional (cfg.dataDir != "/var/lib/rancher/rke2") "--data-dir=${cfg.dataDir}")
            ++ (lib.optional (cfg.token != "") "--token=${cfg.token}")
            ++ (lib.optional (cfg.tokenFile != null) "--token-file=${cfg.tokenFile}")
            ++ (lib.optionals (cfg.role == "server" && cfg.disable != [ ]) (
              map (d: "--disable=${d}") cfg.disable
            ))
            ++ (lib.optional (cfg.nodeName != null) "--node-name=${cfg.nodeName}")
            ++ (lib.optionals (cfg.nodeLabel != [ ]) (map (l: "--node-label=${l}") cfg.nodeLabel))
            ++ (lib.optionals (cfg.nodeTaint != [ ]) (map (t: "--node-taint=${t}") cfg.nodeTaint))
            ++ (lib.optional (cfg.nodeIP != null) "--node-ip=${cfg.nodeIP}")
            ++ (lib.optional (cfg.role == "server" && cfg.agentToken != "") "--agent-token=${cfg.agentToken}")
            ++ (lib.optional (
              cfg.role == "server" && cfg.agentTokenFile != null
            ) "--agent-token-file=${cfg.agentTokenFile}")
            ++ (lib.optional (cfg.serverAddr != "") "--server=${cfg.serverAddr}")
            ++ (lib.optional cfg.selinux "--selinux")
            ++ (lib.optional (cfg.role == "server" && cfg.cni != "canal") "--cni=${cfg.cni}")
            ++ (lib.optional cfg.cisHardening "--profile=${
              if cfg.package.version >= "1.27" then
                "cis"
              else if cfg.package.version >= "1.25" then
                "cis-1.23"
              else
                "cis-1.6"
            }")
            ++ cfg.extraFlags
          )
        }";
    })
    (lib.mkIf (cfg.enable && cfg.cisHardening && cfg.role == "server") {
      users.users.etcd = {
        isSystemUser = true;
        group = "etcd";
      };
      users.groups.etcd = { };
    })
    (lib.mkIf (cfg.enable && cfg.manifests != { } && cfg.role == "server") {
      systemd.services."rke2-${cfg.role}-update-manifests" = {
        script = ''
          mkdir -p ${cfg.dataDir}/server/manifests
          ${lib.pipe cfg.manifests [
            (lib.mapAttrs (name: value: if lib.isPath value then value else pkgs.writeText name value))
            (lib.mapAttrsToList (
              name: value:
              "cp -f ${lib.escapeShellArg value} ${
                lib.escapeShellArg (cfg.dataDir + "/server/manifests/" + name)
              }"
            ))
            (lib.concatStringsSep "\n")
          ]}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      systemd.services."rke2-${cfg.role}" = {
        requires = [ "rke2-${cfg.role}-update-manifests.service" ];
        after = [ "rke2-${cfg.role}-update-manifests.service" ];
      };
    })
    (lib.mkIf (cfg.enable && cfg.useResolved) {
      services.rke2.extraFlags =
        let
          resolv-conf = pkgs.writeText "resolv.conf" ''
            nameserver ${local-dns-ip}
          '';
        in
        [ "--resolv-conf=${resolv-conf}" ];
      systemd.network.netdevs."10-localdns0" = {
        netdevConfig = {
          Name = "localdns0";
          Kind = "dummy";
        };
      };
      systemd.network.networks."10-localdns0" = {
        matchConfig = {
          Name = "localdns0";
        };
        address = [ "169.254.20.20/32" ];
      };
      services.resolved.extraConfig = ''
        DNSStubListenerExtra=169.254.20.20
      '';
    })
  ];
}
