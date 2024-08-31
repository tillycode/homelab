{
  config,
  lib,
  pkgs,
  ...
}:
let
  addresses = config.misc.node-facts.addresses;
  node-ip = lib.filter (x: x != null) [
    addresses.overlay_ipv4
    addresses.overlay_ipv6
  ];
  node-external-ip = lib.filter (x: x != null) [
    addresses.public_ipv4
    # addresses.public_ipv6
  ];
  json = pkgs.formats.json { };
  # This file is modified based on
  # https://github.com/k3s-io/k3s/blob/v1.30.3%2Bk3s1/pkg/agent/flannel/setup_linux.go.
  # We added `conditionsV4` to the portmap plugin to prevent containers which
  # expose port 53 overriding systemd-resolved's DNS port.
  flannel-cni-conf = json.generate "10-flannel.conflist" {
    name = "cbr0";
    cniVersion = "1.0.0";
    plugins = [
      {
        type = "flannel";
        delegate = {
          hairpinMode = true;
          forceAddress = true;
          isDefaultGateway = true;
        };
      }
      {
        type = "portmap";
        capabilities = {
          portMappings = true;
        };
        conditionsV4 = [
          "!"
          "-d"
          "127.0.0.53"
        ];
      }
      {
        type = "bandwidth";
        capabilities = {
          bandwidth = true;
        };
      }
    ];
  };
  resolv-conf-path = "/run/systemd/resolve/resolv.conf";
  resolv-conf-no-search-path = "/etc/resolv.no-search.conf";
in
{
  systemd.paths."resolv-conf-no-search" = {
    wantedBy = [ "k3s.service" ];
    pathConfig = {
      PathChanged = resolv-conf-path;
    };
  };

  systemd.services."resolv-conf-no-search" = {
    before = [ "k3s.service" ];
    after = [ "systemd-resolved.service" ];
    wantedBy = [ "k3s.service" ];
    script = ''
      sed -e "s/^search/# search/" ${resolv-conf-path} > ${resolv-conf-no-search-path}
    '';
    unitConfig.ConditionPathExists = resolv-conf-path;
    serviceConfig.Type = "oneshot";
  };

  services.k3s = {
    enable = true;
    tokenFile = config.sops.secrets."k3s/bootstrap-token".path;
    gracefulNodeShutdown.enable = true;
    extraFlags =
      lib.optionals (lib.length node-ip != 0) [
        "--node-ip"
        (lib.concatStringsSep "," node-ip)
      ]
      ++ lib.optionals (lib.length node-external-ip != 0) [
        "--node-external-ip"
        (lib.concatStringsSep "," node-external-ip)
      ]
      ++ [
        "--flannel-cni-conf"
        (toString flannel-cni-conf)
      ]
      ++ [
        # TODO: depends on tailscale0. When tailscale is restarted, k3s should be restarted too.
        "--flannel-iface"
        "tailscale0"
      ]
      ++ [
        "--resolv-conf"
        resolv-conf-no-search-path
      ];
  };

  sops.secrets."k3s/bootstrap-token" = {
    sopsFile = config.sops-file.common;
  };

  environment.persistence."/persist" = {
    directories = [ "/etc/rancher" ];
  };
}
