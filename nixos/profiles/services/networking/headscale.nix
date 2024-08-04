{ pkgs, lib, ... }:
{
  services.headscale-beta = {
    enable = true;
    settings = lib.mkForce {
      # external domain
      server_url = "http://127.0.0.1:8080";
      listen_addr = "127.0.0.1:8080";
      metrics_listen_addr = "127.0.0.1:9090";
      noise = {
        private_key_path = "/var/lib/headscale/noise_private.key";
      };
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };
      derp = {
        server = {
          enabled = true;
          region_id = 999;
          region_code = "headscale";
          region_name = "Headscale Embedded DERP";
          stun_listen_addr = "0.0.0.0:3478";
          private_key_path = "/var/lib/headscale/derp_server_private.key";
          automatically_add_embedded_derp_region = true;
          # TODO: add public IPv4 and IPv6 addresses
        };
        urls = [ ];
        paths = [ ];
        auto_update_enable = true;
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
      dns_config = {
        override_local_dns = false;
        nameservers = [ "1.1.1.1" ];
        domains = [ ];
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
}
