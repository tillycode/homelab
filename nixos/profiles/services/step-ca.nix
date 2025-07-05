{
  config,
  lib,
  pkgs,
  ...
}:
let
  caName = "szp.io";
  domain = config.domains.step-ca;
  home = config.users.users.step-ca.home;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.step-ca = {
    enable = true;
    address = "127.0.0.1";
    port = config.ports.step-ca;
    intermediatePasswordFile = config.sops.secrets."step-ca/keysPassword".path;
    settings = {
      root = "${home}/certs/root_ca.crt";
      crt = "${home}/certs/intermediate_ca.crt";
      key = "${home}/secrets/intermediate_ca_key";
      dnsNames = [ domain ];
      logger.format = "text";
      db = {
        type = "badgerv2";
        dataSource = "${home}/db";
      };
      authority.provisioners = [
        {
          type = "ACME";
          name = "acme";
        }
        {
          type = "SSHPOP";
          name = "sshpop";
          claims = {
            enableSSHCA = true;
          };
        }
      ];
      tls = {
        cipherSuites = [
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ];
        minVersion = 1.2;
        maxVersion = 1.3;
        renegotiation = false;
      };
      ssh = {
        hostKey = "${home}/secrets/ssh_host_ca_key";
        userKey = "${home}/secrets/ssh_user_ca_key";
      };
      metricsAddress = "[::]:${toString config.ports.step-ca-metrics}";
    };
  };

  ## ---------------------------------------------------------------------------
  ## INITIALIZATION
  ## ---------------------------------------------------------------------------
  systemd.services.step-ca.preStart = ''
    set -o noclobber

    export STEPPATH=$HOME
    if { >"$HOME/.init"; } &>/dev/null; then
      ${lib.getExe pkgs.step-cli} ca init --deployment-type standalone --pki \
        --name ${lib.strings.escapeShellArg caName} \
        --dns ${lib.strings.escapeShellArg domain} \
        --ssh \
        --password-file "''${CREDENTIALS_DIRECTORY}/intermediate_password"
    fi

    set +o noclobber
  '';

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."step-ca/keysPassword" = { };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/step-ca";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  # TODO: limit IP range
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:${toString config.ports.step-ca}";
      extraConfig = ''
        allow 100.120.0.0/16;
        allow fd7a:115c:a1e0:7::/64;
        allow 10.75.0.0/16;
        allow fd42:e16c:cbc4::/48;
        deny all;
      '';
    };
  };
  security.acme.certs.${domain} = {
    server = "https://127.0.0.1:${toString config.ports.step-ca}/acme/acme/directory";
    extraLegoFlags = [ "--tls-skip-verify" ];
  };
}
