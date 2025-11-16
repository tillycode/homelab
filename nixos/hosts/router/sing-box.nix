{ pkgs, config, ... }:
let
  mkGeoipRuleSet = name: {
    tag = name;
    type = "local";
    path = "${pkgs.sing-geoip}/share/sing-box/rule-set/${name}.srs";
  };
  mkGeositeRuleSet = name: {
    tag = name;
    type = "local";
    path = "${pkgs.sing-geosite}/share/sing-box/rule-set/${name}.srs";
  };
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.sing-box = {
    enable = true;
    package = pkgs.sing-box_1_12;
    settings = {
      log.level = "warn";
      experimental = {
        clash_api = {
          external_controller = "0.0.0.0:9090";
          external_ui = pkgs.metacubexd;
          # secret via sops
        };
        cache_file = {
          enabled = true;
          path = "/var/lib/sing-box/cache.db";
          store_fakeip = true;
          store_rdrc = true;
        };
      };
      dns = {
        reverse_mapping = true;
        independent_cache = true;
        final = "remote";
        servers = [
          {
            tag = "local";
            type = "udp";
            server = "223.5.5.5";
          }
          {
            tag = "fakeip";
            type = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "fc00::/18";
          }
          {
            tag = "remote";
            type = "tls";
            server = "8.8.8.8";
            detour = "Proxy";
          }
        ];
        rules = [
          {
            clash_mode = "Direct";
            server = "local";
          }
          {
            clash_mode = "Global";
            query_type = [
              "A"
              "AAAA"
            ];
            server = "fakeip";
          }
          {
            clash_mode = "Global";
            server = "remote";
          }
          {
            query_type = [
              "PTR"
            ];
            domain_suffix = [
              "18.198.in-addr.arpa"
              "19.198.in-addr.arpa"
              "0.0.0.c.f.ip6.arpa"
              "1.0.0.c.f.ip6.arpa"
              "2.0.0.c.f.ip6.arpa"
              "3.0.0.c.f.ip6.arpa"
            ];
            action = "predefined";
            rcode = "NXDOMAIN";
          }
          # DOMAIN rules
          {
            query_type = [
              "A"
              "AAAA"
            ];
            domain_suffix = [
              "byr.pt"
            ];
            server = "fakeip";
          }
          {
            type = "logical";
            mode = "or";
            rules = [
              {
                domain_suffix = [
                  "cn"
                  "steamcontent.com"
                  "steamcontent.akadns.net"
                  "steamserver.net"
                  "aliyuncs.com"
                  "keys.openpgp.org"
                  "szp15.com"
                  "eh578599.xyz"
                ];
              }
              {
                rule_set = [
                  "geosite-cn"
                  "geosite-geolocation-cn"
                ];
              }
            ];
            server = "local";
          }
          # IP rules
          {
            type = "logical";
            mode = "or";
            rules = [
              {
                ip_accept_any = true;
                invert = true;
              }
              {
                ip_is_private = true;
              }
              {
                rule_set = [
                  "geoip-cn"
                ];
              }
            ];
            server = "local";
          }
          # FALLBACK rules
          {
            server = "fakeip";
            query_type = [
              "A"
              "AAAA"
            ];
          }
        ];
      };
      inbounds = [
        {
          tag = "tun";
          type = "tun";
          interface_name = "sing0";
          address = [
            "172.18.0.1/30"
            "fdfe:dcba:9876::1/126"
          ];
          route_address = [
            # fakeip
            "198.18.0.0/15"
            "fc00::/18"
            # telegram according to https://core.telegram.org/resources/cidr.txt
            # FIXME: https://github.com/SagerNet/sing-box/issues/3520
            "91.108.56.0/22"
            "91.108.4.0/22"
            "91.108.8.0/22"
            "91.108.16.0/22"
            "91.108.12.0/22"
            "149.154.160.0/20"
            "91.105.192.0/23"
            "91.108.20.0/22"
            "185.76.151.0/24"
            "2001:b28:f23d::/48"
            "2001:b28:f23f::/48"
            "2001:67c:4e8::/48"
            "2001:b28:f23c::/48"
            "2a0a:f280::/32"
          ];
          auto_route = true;
          auto_redirect = true;
        }
      ];
      outbounds = [
        {
          tag = "direct";
          type = "direct";
        }
        # more outbounds via sops
      ];
      route = {
        default_domain_resolver = "local";
        # sing-box can tolerate missing interface
        default_interface = "ppp0";
        final = "Proxy";
        rules = [
          {
            action = "sniff";
          }
          {
            action = "hijack-dns";
            protocol = "dns";
          }
          {
            action = "route";
            rule_set = [
              "geosite-openai"
              "geosite-anthropic"
              "geosite-google-gemini"
            ];
            outbound = "US";
          }
        ];
        rule_set = [
          (mkGeoipRuleSet "geoip-cn")
          (mkGeositeRuleSet "geosite-cn")
          (mkGeositeRuleSet "geosite-geolocation-cn")
          (mkGeositeRuleSet "geosite-openai")
          (mkGeositeRuleSet "geosite-anthropic")
          (mkGeositeRuleSet "geosite-google-gemini")
          # {
          #   tag = "geoip-telegram";
          #   type = "inline";
          #   # according to https://core.telegram.org/resources/cidr.txt
          #   rules = [
          #     {
          #       ip_cidr = [
          #         "91.105.192.0/23"
          #         "91.108.4.0/22"
          #         "91.108.8.0/22"
          #         "91.108.12.0/22"
          #         "91.108.16.0/22"
          #         "91.108.20.0/22"
          #         "91.108.56.0/22"
          #         "149.154.160.0/20"
          #         "185.76.151.0/24"
          #         "2001:67c:4e8::/48"
          #         "2001:b28:f23c::/48"
          #         "2001:b28:f23d::/48"
          #         "2001:b28:f23f::/48"
          #         "2a0a:f280::/32"
          #       ];
          #     }
          #   ];
          # }
        ];
      };
    };
  };
  systemd.services.sing-box = {
    preStart = ''
      ln -sf "$CREDENTIALS_DIRECTORY/config.json" /run/sing-box/zconfig.json
    '';
    serviceConfig = {
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      DynamicUser = true;
      PrivateDevices = true;
      DeviceAllow = [ "/dev/net/tun" ];
      BindReadOnlyPaths = [ "/dev/net/tun" ];
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = [
        "~CAP_SYS_PTRACE"
        "~CAP_DAC_READ_SEARCH"
      ];
      LoadCredential = "config.json:${config.sops.secrets."sing-box-router/config.json".path}";
      RestrictAddressFamilies = [
        "AF_NETLINK"
        "AF_INET"
        "AF_INET6"
      ];
      SystemCallFilter = "@system-service";
      SystemCallArchitectures = "native";
    };
  };

  systemd.network.networks."40-sing0" = {
    name = "sing0";
    linkConfig.ActivationPolicy = "manual";
    networkConfig = {
      DNS = "172.18.0.2";
      Domains = "~.";
      KeepConfiguration = "static";
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/sing-box";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."sing-box-router/config.json" = {
    restartUnits = [ "sing-box.service" ];
  };
}
