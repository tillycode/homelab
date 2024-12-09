{ lib, pkgs, ... }:
let
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
  derpFile = generateYaml "derp.yaml" {
    regions = {
      "999" = {
        regionid = 999;
        regioncode = "cn";
        regionname = "China";
        nodes = [
          {
            name = "hgh0";
            regionid = 999;
            hostname = "headscale.szp15.com";
            # TODO: import ip from terraform
            ipv4 = "47.96.145.133";
            ipv6 = "2408:4005:3cd:1440:87e:2da4:1f5d:d760";
          }
          {
            name = "hgh1";
            regionid = 999;
            hostname = "derper0.szp15.com";
            ipv4 = "118.178.124.99";
            ipv6 = "2408:4005:3cd:1440:87e:2da4:1f5d:d75f";
          }
        ];
      };
    };
  };
in
{
  environment.etc."headscale/derp.yaml".source = derpFile;

  services.headscale = {
    enable = true;
    settings = lib.mkForce {
      # external domain
      server_url = "https://headscale.szp15.com";
      listen_addr = "127.0.0.1:8080";
      metrics_listen_addr = "127.0.0.1:9090";
      noise = {
        private_key_path = "/var/lib/headscale/noise_private.key";
      };
      prefixes = {
        v4 = "100.64.0.0/16";
        v6 = "fd7a:115c:a1e0::/64";
      };
      derp = {
        server = {
          enabled = true;
          stun_listen_addr = "0.0.0.0:3478";
          private_key_path = "/var/lib/headscale/derp_server_private.key";
          automatically_add_embedded_derp_region = false;
        };
        urls = [ ];
        paths = [ "/etc/headscale/derp.yaml" ];
        auto_update_enabled = true;
        update_frequency = "24h";
      };
      disable_check_updates = true;
      ephemeral_node_inactivity_timeout = "30m";
      database = {
        type = "sqlite";
        sqlite = {
          path = "/var/lib/headscale/db.sqlite";
          write_ahead_log = true;
        };
      };
      log = {
        format = "text";
        level = "info";
      };
      dns = {
        nameservers = {
          split = {
            "k8s.szp.io" = [ "100.64.0.4" ];
          };
        };
        search_domains = [ ];
        magic_dns = true;
        base_domain = "nodes.szp.io";
      };
      unix_socket = "/var/run/headscale/headscale.sock";
      unix_socket_permission = "0770";
      logtail = {
        enabled = false;
      };
      randomize_client_port = false;
    };
  };

  systemd.services.headscale = {
    restartTriggers = [ derpFile ];
  };
}
