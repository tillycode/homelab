{
  config,
  pkgs,
  lib,
  ...
}:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.sing-box = {
    enable = true;
    package = pkgs.sing-box_1_12;
    settings = {
      log.level = "warn";
      dns.servers = [
        {
          tag = "local";
          type = "udp";
          server = "1.1.1.1";
        }
      ];
      outbounds = {
        _secret = config.sops.secrets."sing-box-global/outbounds".path;
        quote = false;
      };
      inbounds = [
        {
          tag = "tun";
          type = "tun";
          interface_name = "sing0";
          address = [
            config.CIDRs.sing-box-tun-v4
            config.CIDRs.sing-box-tun-v6
          ];
          route_address = [
            config.CIDRs.tailnet-v4
            config.CIDRs.tailnet-v6
            config.CIDRs.incus-v4
            config.CIDRs.incus-v6
          ];
          auto_route = true;
        }
      ];
      route = {
        auto_detect_interface = true;
        default_domain_resolver = "local";
        rules = [
          {
            action = "reject";
            invert = true;
            ip_cidr = [
              config.CIDRs.tailnet-v4
              config.CIDRs.tailnet-v6
              config.CIDRs.incus-v4
              config.CIDRs.incus-v6
            ];
          }
        ];
        final = "hgh0";
      };
    };

  };

  systemd.services.sing-box = {
    # let sing-box not invoke resolvectl
    environment.PATH = lib.mkForce (
      lib.makeBinPath [
        pkgs.coreutils
      ]
    );
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.trustedInterfaces = [
    "sing0"
  ];

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."sing-box-global/outbounds" = { };
}
