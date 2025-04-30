{
  config,
  utils,
  lib,
  ...
}:
let
  cfg = config.services.xray;
  credentialsDirectory = "/run/credentials/xray.service";
  domain = config.domains.xray;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.xray.enable = true;
  services.xray.settings = {
    log = {
      logLevel = "warning";
    };
    # TODO: stats service
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
            xver = 2;
            serverNames = [ domain ];
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
      }
    ];
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."xray/private-key" = { };
  sops.secrets."xray/short-id" = { };
  sops.secrets."xray/clients.json" = { };

  ## ---------------------------------------------------------------------------
  ## HACKS
  ## ---------------------------------------------------------------------------
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

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      root = "/var/www/xray/non-existent";
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/www/xray 0755 nginx nginx - -"
  ];
}
