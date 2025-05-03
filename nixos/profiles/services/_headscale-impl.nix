{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.headscale;
  stateDir = "/var/lib/headscale";
  oidcClientID = "295806288846192716";

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
  ## OPTIONS
  ## ---------------------------------------------------------------------------
  options.services.headscale = {
    publicDomain = lib.mkOption {
      type = lib.types.str;
    };
    baseDomain = lib.mkOption {
      type = lib.types.str;
    };
    prefixV4 = lib.mkOption {
      type = lib.types.str;
    };
    prefixV6 = lib.mkOption {
      type = lib.types.str;
    };
    nameserver = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nameserverDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    routes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    predefinedIPs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.length cfg.nameserverDomains > 0 -> cfg.nameserver != null;
        message = "nameserver must be set if nameserverDomains is set";
      }
    ];

    ## -------------------------------------------------------------------------
    ## CONFIGURATION
    ## -------------------------------------------------------------------------
    services.headscale.enable = true;
    services.headscale.settings = {
      server_url = "https://${cfg.publicDomain}";
      listen_addr = "127.0.0.1:${toString config.ports.headscale}";
      metrics_listen_addr = "[::]:${toString config.ports.headscale-metrics}";
      noise.private_key_path = "${stateDir}/noise_private.key";
      prefixes = {
        v4 = cfg.prefixV4;
        v6 = cfg.prefixV6;
        allocation = "random";
      };

      # DERP
      derp = {
        server = {
          enabled = true;
          stun_listen_addr = "0.0.0.0:3478";
          private_key_path = "${stateDir}/derp_server_private.key";
          automatically_add_embedded_derp_region = false;
        };
        urls = [ ];
      };
      derp.paths =
        let
          derpFile = generateYaml "derp.yaml" {
            regions = {
              "900" = {
                regionid = 900;
                regioncode = "default";
                regionname = "Default";
                nodes = [
                  {
                    name = "900a";
                    regionid = 900;
                    hostname = cfg.publicDomain;
                  }
                ];
              };
            };
          };
        in
        [ derpFile ];

      disable_check_updates = true;
      ephemeral_node_inactivity_timeout = "120s";
      database = {
        type = "sqlite";
        sqlite = {
          path = "${stateDir}/db.sqlite";
          write_ahead_log = true;
        };
      };
      log = {
        format = "text";
        level = "info";
      };

      # POLICY
      # https://github.com/juanfont/headscale/blob/v0.25.1/hscontrol/policy/acls_types.go
      policy = {
        mode = "file";
        path = jsonFormat.generate "policy.json" {
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
          # There are 2 ways for a node to gain a tag:
          #
          # 1. preauth key: assign the tag when generating the preauth key
          # 2. OIDC: add `tagOwners`
          #
          # We'll use preauth key to authenticate servers and OIDC for
          # mobile phones and ad-hoc devices.
          #
          # For servers, the preauth key will have the tag server.
          tagOwners = {
            # "tag:example" = [ "group:admin" ];
          };
          autoApprovers = lib.pipe cfg.routes [
            (lib.map (x: {
              name = x;
              value = [ "tag:server" ];
            }))
            lib.listToAttrs
          ];
        };
      };

      # DNS
      dns = {
        magic_dns = true;
        base_domain = cfg.baseDomain;
        nameservers.split = lib.pipe cfg.nameserverDomains [
          (lib.map (x: {
            name = x;
            value = [ cfg.nameserver ];
          }))
          lib.listToAttrs
        ];
        search_domains = [ ];
      };

      unix_socket = "/run/headscale/headscale.sock";
      unix_socket_permission = "0770";
      oidc = {
        only_start_if_oidc_is_available = false;
        issuer = "https://${config.domains.sso}";
        client_id = oidcClientID;
        client_secret_path = config.sops.secrets."headscale/oidcClientSecret".path;
        expiry = 0; # disable expiry
        allowed_groups = [ "admin" ];
        pkce.enabled = true;
      };
      logtail.enabled = false;
      randomize_client_port = false;
    };

    ## -------------------------------------------------------------------------
    ## SECRETS
    ## -------------------------------------------------------------------------
    sops.secrets."headscale/oidcClientSecret" = {
      owner = "headscale";
      group = "headscale";
    };

    ## -------------------------------------------------------------------------
    ## FIREWALL
    ## -------------------------------------------------------------------------
    networking.firewall = {
      allowedUDPPorts = [ 3478 ]; # STUN
    };

    ## -------------------------------------------------------------------------
    ## PERSISTENCE
    ## -------------------------------------------------------------------------
    environment.persistence.default.directories = [
      {
        directory = stateDir;
        user = "headscale";
        group = "headscale";
        mode = "0700";
      }
    ];

    ## -------------------------------------------------------------------------
    ## INGRESS
    ## -------------------------------------------------------------------------
    services.nginx.virtualHosts.${cfg.publicDomain} = {
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

    ## -------------------------------------------------------------------------
    ## PREDEFINED IP
    ## -------------------------------------------------------------------------
    systemd.services.headscale.preStart = lib.pipe cfg.predefinedIPs [
      lib.attrsToList
      (lib.map (
        x:
        "${lib.getExe pkgs.hschip} ${
          lib.escapeShellArgs [
            x.name
            x.value
          ]
        }"
      ))
      lib.concatLines
    ];
  };
}
