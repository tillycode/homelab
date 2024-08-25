{ config, lib, ... }:
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
in
{
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
        # TODO: depends on tailscale0. When tailscale is restarted, k3s should be restarted too.
        "--flannel-iface"
        "tailscale0"
      ];
  };

  sops.secrets."k3s/bootstrap-token" = {
    sopsFile = config.sops-file.common;
  };

  environment.persistence."/persist" = {
    directories = [ "/etc/rancher" ];
  };
}
