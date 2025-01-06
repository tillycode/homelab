{
  config,
  lib,
  pkgs,
  ...
}:
let
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  baseDomain = "ts.szp.io";
  splitDomain = {
    "svc.szp.io" = [ "100.71.0.1" ];
    "vm.szp.io" = [ "100.71.0.1" ];
  };

  # https://github.com/juanfont/headscale/blob/v0.23.0/hscontrol/policy/acls_types.go
  policy = jsonFormat.generate "policy.json" {
    groups = {
      "group:admin" = [ "ziping-sun" ];
    };
    acls = [
      {
        action = "accept";
        src = [ "*" ];
        dst = [ "*:*" ];
      }
    ];
    # There are 3 tag fields of a node.
    # 1. forcedTags: assigned using Preauth key or APIs
    # 2. validTags: gained by advertising during OIDC. These tags must be declared below.
    # 3. invalidTags: undeclared tags during OIDC.
    tagOwners = { };
    autoApprovers = {
      routes = {
        # kubernetes
        "10.42.0.0/16" = [ "tag:server" ];
        "10.43.0.0/16" = [ "tag:server" ];
        # podman
        "10.88.0.0/16" = [ "tag:server" ];
        # incus
        "10.75.0.0/16" = [ "tag:incus" ];
        "fd42:e16c:cbc4::/48" = [ "tag:incus" ];
      };
    };
  };
  derpFile = generateYaml "derp.yaml" {
    regions = {
      "900" = {
        regionid = 900;
        regioncode = "hgh";
        regionname = "Hang Zhou";
        nodes = [
          {
            name = "900a";
            regionid = 900;
            hostname = config.domains.tailnet;
          }
        ];
      };
    };
  };
  oidcClientID = "295806288846192716";

  prefixV4 = "100.71.0.0/16";
  prefixV6 = "fd7a:115c:a1e0:7::/64";
  stateDir = "/var/lib/headscale";

  # helpers
  jsonFormat = pkgs.formats.json { };
  generateYaml =
    name: value:
    pkgs.callPackage (
      { runCommand, remarshal }:
      runCommand name
        {
          nativeBuildInputs = [ remarshal ];
          value = builtins.toJSON value;
          passAsFile = [ "value" ];
          preferLocalBuild = true;
        }
        ''
          json2yaml "$valuePath" "$out"
          # Hack to support int yaml key
          sed -i -e "s/'\([0-9]\+\)':/\1:/" $out
        ''
    ) { };
in
{
  ## ---------------------------------------------------------------------------
  ## SERVICES
  ## ---------------------------------------------------------------------------
  services.headscale = {
    enable = true;
    settings = lib.mkForce {
      server_url = "https://${config.domains.tailnet}";
      listen_addr = "127.0.0.1:${toString config.ports.headscale}";
      metrics_listen_addr = "127.0.0.1:${toString config.ports.headscale-metrics}";

      noise = {
        private_key_path = "${stateDir}/noise_private.key";
      };

      prefixes = {
        v4 = prefixV4;
        v6 = prefixV6;
        allocation = "random";
      };
      derp = {
        server = {
          enabled = true;
          stun_listen_addr = "0.0.0.0:3478";
          private_key_path = "${stateDir}/derp_server_private.key";
          automatically_add_embedded_derp_region = false;
        };
        urls = [ ];
        paths = [ derpFile ];
      };
      disable_check_updates = true;
      ephemeral_node_inactivity_timeout = "120s";
      database = {
        type = "sqlite";
        gorm = {
          prepare_stmt = true;
        };
        sqlite = {
          path = "${stateDir}/db.sqlite";
          write_ahead_log = true;
        };
      };
      log = {
        format = "text";
        level = "info";
      };
      policy = {
        mode = "file";
        path = policy;
      };
      dns = {
        magic_dns = true;
        base_domain = baseDomain;
        nameservers.split = splitDomain;
        search_domains = [ ];
      };
      unix_socket = "/var/run/headscale/headscale.sock";
      unix_socket_permission = "0770";
      oidc = {
        only_start_if_oidc_is_available = false;
        issuer = "https://login.szp15.com";
        client_id = oidcClientID;
        client_secret_path = config.sops.secrets."headscale/oidcClientSecret".path;
        strip_email_domain = true;
      };
      logtail = {
        enabled = false;
      };
      randomize_client_port = false;
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."headscale/oidcClientSecret" = {
    owner = "headscale";
    group = "headscale";
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall = {
    allowedUDPPorts = [ 3478 ];
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = stateDir;
      user = "headscale";
      group = "headscale";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${config.domains.tailnet} = {
    enableACME = true;
    forceSSL = true;
    locations."/web/" = {
      alias = "${pkgs.headscale-ui}/";
      tryFiles = "$uri $uri/index.html =404";
    };
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.headscale}";
      proxyWebsockets = true;
    };
    locations."= /" = {
      return = "301 /web/";
    };
  };

  ## ---------------------------------------------------------------------------
  ## DECLARATIVE PREDEFINED IP
  ## ---------------------------------------------------------------------------
  systemd.services.headscale.preStart = ''
    ${lib.getExe pkgs.hschip} ${config.networking.hostName} 100.71.0.1
  '';
}
