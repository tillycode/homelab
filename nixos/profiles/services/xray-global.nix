{ config, ... }:
{
  imports = [
    ./_xray-impl.nix
  ];

  services.xray = {
    domain = config.domains.xray-global;
    privateCIDRs = [
      config.CIDRs.tailnet-global-v4
      config.CIDRs.tailnet-global-v6
    ];
    privateNameserver = "100.100.100.100";
  };
}
