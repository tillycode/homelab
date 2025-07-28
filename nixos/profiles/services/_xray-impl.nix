{
  config,
  lib,
  utils,
  ...
}:
let
  cfg = config.services.xray;
  credentialsDirectory = "/run/credentials/xray.service";
in
{

  ## ---------------------------------------------------------------------------
  ## OPTIONS
  ## ---------------------------------------------------------------------------
  options.services.xray = {
    domain = lib.mkOption {
      type = lib.types.str;
    };
    privateCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    privateNameserver = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nameserver = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = {
    assertions = [
      {
        assertion = (lib.length cfg.privateCIDRs != 0) -> (cfg.privateNameserver != null);
        message = "privateNameserver must be set if privateCIDRs is set";
      }
    ];

    ## ---------------------------------------------------------------------------
    ## CONFIGURATION
    ## ---------------------------------------------------------------------------
    services.xray.enable = true;
    services.xray.settings = lib.mkMerge [
      {
        log.logLevel = "warning";
        # TODO: stats service (xray-exporter)
        inbounds = [
          {
            protocol = "vless";
            port = 443;
            # both IPv4 and IPv6 will be listened
            listen = "::";
            settings = {
              # array of {id, email, flow} where flow = "xtls-rprx-vision"
              clients = {
                _secret = "${credentialsDirectory}/clients.json";
                quote = false;
              };
              decryption = "none";
            };
            streamSettings = {
              network = "tcp";
              security = "reality";
              realitySettings = {
                dest = "[::1]:${toString config.ports.xray-nginx-https}";
                # dest = "/run/nginx/nginx-xray.sock";
                xver = 2;
                serverNames = [ cfg.domain ];
                privateKey = {
                  _secret = "${credentialsDirectory}/private-key";
                };
                shortIds = [
                  {
                    _secret = "${credentialsDirectory}/short-id";
                  }
                ];
              };
            };
            sniffing = {
              enabled = true;
              destOverride = [
                "http"
                "tls"
                "quic"
              ];
              routeOnly = true;
            };
          }
        ];
        outbounds = [
          {
            protocol = "freedom";
            tag = "direct";
            settings = {
              domainStrategy = if cfg.nameserver != null then "UseIP" else "AsIs";
            };
          }
          {
            protocol = "blackhole";
            tag = "blocked";
          }
        ]
        ++ lib.optional (cfg.privateNameserver != null) {
          protocol = "freedom";
          tag = "private-dns";
          settings = {
            redirect = "${cfg.privateNameserver}:53";
          };
        };
        routing.rules =
          lib.optionals (lib.length cfg.privateCIDRs != 0) [
            {
              ip = cfg.privateCIDRs;
              user = [ "me@szp.io" ];
              port = "53";
              outboundTag = "private-dns";
            }
            {
              ip = cfg.privateCIDRs;
              user = [ "me@szp.io" ];
              outboundTag = "direct";
            }
          ]
          ++ [
            {
              ip = [ "geoip:private" ];
              outboundTag = "blocked";
            }
          ];
      }
      (lib.mkIf (cfg.nameserver != null) {
        dns.servers = [
          cfg.nameserver
        ];
      })
    ];

    ## ---------------------------------------------------------------------------
    ## SECRETS
    ## ---------------------------------------------------------------------------
    sops.secrets."xray/private-key" = { };
    sops.secrets."xray/short-id" = { };
    sops.secrets."xray/clients.json" = { };

    systemd.services.xray = {
      preStart = utils.genJqSecretsReplacementSnippet cfg.settings "/run/xray/config.json";
      script = lib.mkForce ''
        exec "${cfg.package}/bin/xray" -config "/run/xray/config.json"
      '';
      serviceConfig = {
        RuntimeDirectory = "xray";
        RuntimeDirectoryMode = "0700";
        LoadCredential = lib.mkForce [
          "private-key:${config.sops.secrets."xray/private-key".path}"
          "short-id:${config.sops.secrets."xray/short-id".path}"
          "clients.json:${config.sops.secrets."xray/clients.json".path}"
        ];
      };
    };

    users.users.xray = {
      isSystemUser = true;
      group = "xray";
      extraGroups = [ "nginx" ];
    };
    users.groups.xray = { };

    ## ---------------------------------------------------------------------------
    ## INGRESS
    ## ---------------------------------------------------------------------------
    services.nginx.virtualHosts."${cfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = "/var/www/xray/non-existent";
      };
    };
    systemd.tmpfiles.rules = [
      "d /var/www/xray 0755 nginx nginx - -"
    ];

    services.nginx.enableProxyProtocol = true;
    services.nginx.defaultSSLListenPort = config.ports.xray-nginx-https;
    services.nginx.defaultSSLListenAddresses = [
      # FIXME: there seems to be a bug regarding unix sockets combined with
      #    proxy protocol relay.
      #
      # "unix:/run/nginx/nginx-xray.sock"
      "[::1]"
    ];
    services.nginx.proxyProtocolTrustedIPs = [
      "::1"
    ];
  };
}
