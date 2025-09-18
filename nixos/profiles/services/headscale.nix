{ config, ... }:
{
  imports = [
    ./_headscale-impl.nix
  ];

  services.headscale = {
    publicDomain = config.domains.tailnet;
    baseDomain = config.domains.base-tailnet;
    prefixV4 = config.CIDRs.tailnet-v4;
    prefixV6 = config.CIDRs.tailnet-v6;

    nameserver = config.IPs.coredns;
    nameserverDomains = with config.domains; [
      base-tailnet-global
      base-incus
      base-service
      base-k8s
    ];

    routes = with config.CIDRs; [
      incus-v4
      incus-v6
    ];
    # TODO: refactor this
    predefinedIPs = {
      hgh0 = config.IPs.coredns;
    };
  };
}
