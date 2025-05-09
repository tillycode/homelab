{ config, ... }:
{
  imports = [
    ./_tailscale-impl.nix
  ];

  services.tailscale = {
    loginServer = "https://${config.domains.tailnet-global}";
    authKeySecretName = "authkeyGlobal";
    prefixV4 = config.CIDRs.tailnet-global-v4;
  };
}
