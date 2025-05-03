{ config, ... }:
{
  imports = [
    ./_headscale-impl.nix
  ];

  services.headscale = {
    publicDomain = config.domains.tailnet-global;
    baseDomain = config.domains.base-tailnet-global;
    prefixV4 = config.CIDRs.tailnet-global-v4;
    prefixV6 = config.CIDRs.tailnet-global-v6;

    nameserver = config.IPs.coredns;
    nameserverDomains = with config.domains; [
      base-tailnet
      base-incus
      base-service
    ];

    predefinedIPs = {
      hkg0 = config.IPs.coredns-global;
    };
  };
}
