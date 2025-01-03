{ config, pkgs, ... }:
let
  loginServer = "https://${config.domains.tailnet}";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.tailscale = {
    enable = true;
    openFirewall = true;

    authKeyFile = config.sops.secrets."tailscale/authkey".path;
    extraUpFlags = [
      "--login-server"
      loginServer
    ];
    extraDaemonFlags = [ "--no-logs-no-support" ];
    extraSetFlags = [ "--accept-routes" ];
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."tailscale/authkey" = { };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      # owned by root
      directory = "/var/lib/tailscale";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## HACKS
  ## ---------------------------------------------------------------------------
  # FIXME: Tailscale hardcodes the following iptables rules
  #     -A ts-forward -s 100.64.0.0/10 -o tailscale0 -j DROP
  #     -A ts-input -s 100.64.0.0/10 ! -i tailscale0 -j DROP
  #   See https://github.com/tailscale/tailscale/blob/v1.70.0/util/linuxfw/iptables_runner.go#L327-L330.
  #   So we patched tailscale to allow customizing the CGNAT range.
  services.tailscale.package = pkgs.tailscale-patched;
  systemd.services.tailscaled.environment.TS_CGNAT_RANGE = "100.71.0.0/16";
}
