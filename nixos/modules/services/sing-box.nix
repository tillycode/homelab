{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.sing-box;
  fakeipCfg = lib.findFirst (
    cfg: cfg.type == "fakeip"
  ) (throw "no fakeip DNS server found") cfg.settings.dns.servers;
  settingsFormat = pkgs.formats.json { };

  mkGeoipRuleSet = name: {
    tag = name;
    type = "remote";
    format = "binary";
    url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/${name}.srs";
  };
  mkGeositeRuleSet = name: {
    tag = name;
    type = "remote";
    format = "binary";
    url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/${name}.srs";
  };

  staticConfig = {
    outbounds = [
      {
        tag = "direct";
        type = "direct";
      }
    ];
  };
  staticConfigFile = settingsFormat.generate "zconfig.json" staticConfig;
in
{
  options = {
    services.sing-box = {
      enableCustom = lib.mkEnableOption "Enable sing-box";
      enableClashApi = lib.mkEnableOption "Enable clash api";
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the firewall for sing-box";
      };
      clashPort = lib.mkOption {
        type = lib.types.int;
        default = 9090;
      };
      mixedPort = lib.mkOption {
        type = lib.types.int;
        default = 12311;
      };
      outboundsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      defaultOutbound = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      dnsRules = lib.mkOption {
        type = lib.types.listOf settingsFormat.type;
        default = [ ];
      };
      routeRules = lib.mkOption {
        type = lib.types.listOf settingsFormat.type;
        default = [ ];
      };
      ruleSet = lib.mkOption {
        type = lib.types.listOf settingsFormat.type;
        default = [ ];
      };
      geoipRuleSet = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      geositeRuleSet = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      tunExtraRoutes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };
  config = lib.mkIf cfg.enableCustom {
    assertions = [
      {
        assertion = cfg.outboundsFile != null;
        message = "You must provide outboundsFile if sing-box is enabled";
      }
    ];

    networking.firewall.trustedInterfaces = lib.optionals cfg.openFirewall [
      "sing0"
    ];

    services.sing-box.settings = {
      log = {
        level = "warn";
      };
      experimental = {
        cache_file = {
          enabled = true;
          path = "/var/lib/sing-box/cache.db";
          store_fakeip = true;
          # FIXME: store_rdrc seems not to work properly if DNS rules rely on
          #   GeoIP. So we disable it for now. Check SagerNet/sing-box#1798 for
          #   more details.
          # store_rdrc = true;
        };
        clash_api = lib.mkIf cfg.enableClashApi {
          external_controller = "[::1]:${toString cfg.clashPort}";
        };
      };
      dns = {
        independent_cache = true;
        reverse_mapping = true;
        final = "remote";
        servers = [
          {
            tag = "remote";
            type = "tls";
            server = "8.8.8.8";
            detour = "proxy";
          }
          {
            tag = "local";
            type = "udp";
            server = "223.5.5.5";
          }
          {
            tag = "proxy";
            type = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "fc00::/18";
          }
        ];
        rules =
          (lib.lists.optionals cfg.enableClashApi [
            # direct if clash mode is Direct
            {
              clash_mode = "Direct";
              action = "route";
              server = "local";
            }
            {
              # remote if clash mode is Global and type is A or AAAA
              clash_mode = "Global";
              query_type = [
                "A"
                "AAAA"
              ];
              action = "route";
              server = "proxy";
            }
            {
              # google if clash mode is Global
              clash_mode = "Global";
              action = "route";
              server = "remote";
            }
          ])
          ++ [
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
              action = "reject";
            }
          ]
          ++ cfg.dnsRules
          ++ [
            {
              query_type = [
                "A"
                "AAAA"
              ];
              server = "proxy";
            }
          ];
      };
      outbounds = {
        _secret = cfg.outboundsFile;
        quote = false;
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
            fakeipCfg.inet4_range
            fakeipCfg.inet6_range
          ] ++ cfg.tunExtraRoutes;
          auto_route = true;
        }
        {
          tag = "mixed";
          type = "mixed";
          listen = "::1";
          listen_port = cfg.mixedPort;
        }
      ];
      route = {
        auto_detect_interface = true;
        default_domain_resolver = "local";
        final = lib.mkIf (cfg.defaultOutbound != null) cfg.defaultOutbound;
        rules = cfg.routeRules;
        rule_set =
          cfg.ruleSet
          ++ (lib.map mkGeoipRuleSet cfg.geoipRuleSet)
          ++ (lib.map mkGeositeRuleSet cfg.geositeRuleSet);
      };
    };

    # systemd.tmpfiles.rules = [
    #   "L+ /run/sing-box/zconfig.json - - - - ${staticConfigFile}"
    # ];
    systemd.services.sing-box.preStart = ''
      ln -sf ${staticConfigFile} /run/sing-box/zconfig.json
    '';
    systemd.services.sing-box.restartTriggers = [
      staticConfigFile
    ];
  };
}
