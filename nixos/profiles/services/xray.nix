{ config, ... }:
{
  imports = [
    ./_xray-impl.nix
  ];

  services.xray = {
    domain = config.domains.xray;
    nameserver = "223.5.5.5";
    privateCIDRs = [
      config.CIDRs.tailnet-v4
      config.CIDRs.tailnet-v6
      config.CIDRs.incus-v4
      config.CIDRs.incus-v6
    ];
    privateNameserver = config.IPs.coredns;
  };
}
