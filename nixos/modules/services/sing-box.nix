{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.sing-box-client;
  tunCfg = lib.findFirst (cfg: cfg.type == "tun") (throw "no tun inbound") cfg.settings.inbounds;
  fakeipCfg = cfg.settings.dns.fakeip;

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "sing-box.json" cfg.settings;

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
in
{
  options = {
    services.sing-box-client = {
      enable = lib.mkEnableOption "Enable sing-box client service";
      enableClashApi = lib.mkEnableOption "Enable clash api";
      useLocalDNSServer = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use local DNS server";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the firewall for sing-box";
      };
      package = lib.mkPackageOption pkgs "sing-box" { };
      clashPort = lib.mkOption {
        type = lib.types.int;
        default = 9090;
      };
      mixedPort = lib.mkOption {
        type = lib.types.int;
        default = 12311;
      };
      outbounds = lib.mkOption {
        type = lib.types.listOf settingsFormat.type;
        default = [ ];
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
      settings = lib.mkOption {
        type = settingsFormat.type;
        internal = true;
        default = { };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall.trustedInterfaces = lib.optionals cfg.openFirewall [
      "sing0"
    ];

    services.sing-box-client.settings = {
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
        servers = [
          {
            tag = "google";
            address = "tls://8.8.8.8";
          }
          {
            tag = "local";
            address = "223.5.5.5";
            detour = "direct";
          }
          {
            tag = "remote";
            address = "fakeip";
          }
          {
            tag = "block";
            address = "rcode://success";
          }
        ];
        rules =
          [
            # local if initiated from sing-box
            {
              outbound = "any";
              server = "local";
            }
          ]
          ++ (lib.lists.optionals cfg.enableClashApi [
            # direct if clash mode is Direct
            {
              clash_mode = "Direct";
              server = "local";
            }
            {
              # remote if clash mode is Global and type is A or AAAA
              clash_mode = "Global";
              query_type = [
                "A"
                "AAAA"
              ];
              server = "remote";
            }
            {
              # google if clash mode is Global
              clash_mode = "Global";
              server = "google";
            }
          ])
          ++ cfg.dnsRules
          ++ [
            {
              query_type = [
                "A"
                "AAAA"
              ];
              server = "remote";
            }
          ];
        final = "google";
        independent_cache = true;
        fakeip = {
          enabled = true;
          inet4_range = "198.18.0.0/15";
          inet6_range = "fc00::/18";
        };
      };
      outbounds = cfg.outbounds ++ [
        {
          tag = "direct";
          type = "direct";
        }
        {
          tag = "block";
          type = "block";
        }
        {
          tag = "dns-out";
          type = "dns";
        }
      ];
      inbounds = [
        {
          tag = "tun";
          type = "tun";
          interface_name = "sing0";
          address = [
            "172.18.0.1/30"
            "fdfe:dcba:9876::1/126"
          ];
          sniff = true;
        }
        {
          tag = "mixed";
          type = "mixed";
          listen = "::1";
          listen_port = 12311;
        }
      ];
      route = {
        rules = [
          {
            protocol = "dns";
            outbound = "dns-out";
          }
        ] ++ cfg.routeRules;
        rule_set =
          cfg.ruleSet
          ++ (lib.map mkGeoipRuleSet cfg.geoipRuleSet)
          ++ (lib.map mkGeositeRuleSet cfg.geositeRuleSet);
        final = lib.mkIf (cfg.defaultOutbound != null) cfg.defaultOutbound;
        auto_detect_interface = true;
      };
    };

    systemd.network.netdevs."10-sing0" = {
      netdevConfig = {
        Name = "sing0";
        Kind = "tun";
      };
    };

    systemd.network.networks."10-sing0" = {
      name = "sing0";
      linkConfig = {
        RequiredForOnline = false;
      };
      # this should match the tun inbound and fake IP in sing-box.json
      networkConfig = {
        Address = tunCfg.address ++ [
          # fake IP
          fakeipCfg.inet4_range
          fakeipCfg.inet6_range
        ];
        DNS = "172.18.0.2";
        DNSDefaultRoute = false;
        ConfigureWithoutCarrier = true;
        Domains = "~.";
      };
    };

    systemd.services.sing-box-client = {
      enable = true;
      description = "Sing-box proxy client";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ settingsFile ];

      preStart =
        let
          resolveConf = /run/systemd/resolve/resolv.conf;
        in
        # remove stale config.json
        ''
          rm -f "$STATE_DIRECTORY/config.json"
        ''
        # merge config.json
        + (
          if cfg.outboundsFile != null then
            ''
              ${pkgs.jq}/bin/jq -s '.[1] as $outbounds | .[0] | (.outbounds |= $outbounds + .)' \
                "$CREDENTIALS_DIRECTORY/sing-box.json" "$CREDENTIALS_DIRECTORY/outbounds.json" \
                > "$STATE_DIRECTORY/config.json"
            ''
          else
            ''
              cp "$CREDENTIALS_DIRECTORY/sing-box.json" "$STATE_DIRECTORY/config.json"
            ''
        )
        # inject local DNS server
        + lib.strings.optionalString cfg.useLocalDNSServer ''
          nameserver=""
          while true; do
            while IFS= read -r line; do
              if [[ $line != "172.18.0.2" ]]; then
                nameserver=$line
                break
              fi
            done < <(${pkgs.gawk}/bin/awk '/^nameserver / { print $2 }' ${lib.strings.escapeShellArg resolveConf})
            [[ -n $nameserver ]] && break
            sleep 1;
          done

          ${pkgs.jq}/bin/jq --arg nameserver "$nameserver" '.dns.servers |= map((select(.tag == "local") | .address) = $nameserver)' \
            "$STATE_DIRECTORY/config.json" > "$STATE_DIRECTORY/config.json.tmp"
          mv "$STATE_DIRECTORY/config.json.tmp" "$STATE_DIRECTORY/config.json"
        '';

      serviceConfig = {
        LoadCredential =
          (lib.lists.optional (cfg.outboundsFile != null) [ "outbounds.json:${cfg.outboundsFile}" ])
          ++ [ "sing-box.json:${settingsFile}" ];
        ExecStart = "${cfg.package}/bin/sing-box run -c \"\${STATE_DIRECTORY}/config.json\"";
        DynamicUser = true;
        User = "sing-box";
        Group = "sing-box";
        Restart = "always";
        WorkingDirectory = "/tmp";
        StateDirectory = "sing-box";

        AmbientCapabilities = "";
        BindPaths = "/dev/net/tun";
        CapabilityBoundingSet = "";
        DeviceAllow = "/dev/net/tun rw";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX AF_NETLINK";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        UMask = "0077";
        BindReadOnlyPaths = lib.optionals cfg.useLocalDNSServer [
          "/run/systemd/resolve/resolv.conf"
        ];
      };
    };
  };
}
