{ config, ... }:
{
  imports = [
    ./_tailscale-impl.nix
  ];

  services.tailscale = {
    loginServer = "https://${config.domains.tailnet}";
    authKeySecretName = "authkey";
    prefixV4 = config.CIDRs.tailnet-v4;
  };
}
