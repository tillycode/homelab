{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tailscale;
in
{

  ## ---------------------------------------------------------------------------
  ## OPTIONS
  ## ---------------------------------------------------------------------------
  options.services.tailscale = {
    loginServer = lib.mkOption {
      type = lib.types.str;
    };
    authKeySecretName = lib.mkOption {
      type = lib.types.str;
    };
    prefixV4 = lib.mkOption {
      type = lib.types.str;
    };
  };

  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  config.services.tailscale = {
    enable = true;
    openFirewall = true;

    authKeyFile = config.sops.secrets."tailscale/${cfg.authKeySecretName}".path;
    extraUpFlags = [
      "--login-server"
      cfg.loginServer
    ];
    extraDaemonFlags = [ "--no-logs-no-support" ];
    extraSetFlags = [ "--accept-routes" ];
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  config.sops.secrets."tailscale/${cfg.authKeySecretName}" = { };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  config.environment.persistence.default.directories = [
    {
      # owned by root
      directory = "/var/lib/tailscale";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  config.networking.firewall.trustedInterfaces = [ "tailscale0" ];

  ## ---------------------------------------------------------------------------
  ## HACKS
  ## ---------------------------------------------------------------------------
  # FIXME: Tailscale hardcodes the following iptables rules
  #     -A ts-forward -s 100.64.0.0/10 -o tailscale0 -j DROP
  #     -A ts-input -s 100.64.0.0/10 ! -i tailscale0 -j DROP
  #   See https://github.com/tailscale/tailscale/blob/v1.70.0/util/linuxfw/iptables_runner.go#L327-L330.
  #   So we patched tailscale to allow customizing the CGNAT range.
  config.services.tailscale.package = pkgs.tailscale-patched;
  config.systemd.services.tailscaled.environment = {
    TS_CGNAT_RANGE = cfg.prefixV4;
    TS_DEBUG_MTU = "1330"; # 1280 (minimum MTU) + 50 (vxlan overhead)
  };
  config.systemd.services.tailscaled.serviceConfig = {
    RestrictNetworkInterfaces = "~sing0 incusbr0 cilium_host";
  };
}
