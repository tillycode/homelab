{ config, lib, ... }:
let
  local_https_port = 10443;
  k8s_http_port = 8000;
  k8s_https_port = 8443;

  ssl_server_names = lib.pipe config.services.nginx.virtualHosts [
    (lib.filterAttrs (k: v: v.onlySSL || v.enableSSL || v.addSSL || v.forceSSL))
    (lib.mapAttrsToList (
      k: v: {
        name = lib.replaceStrings [ "." ] [ "-" ] k;
        domain = k;
      }
    ))
  ];
  ssl_server_name_map = lib.concatMapStrings (v: "${v.domain} ${v.name};") ssl_server_names;
  upstream_map = lib.concatMapStrings (v: ''
    upstream ${v.name} {
      server 127.0.0.1:${toString local_https_port};
    }
  '') ssl_server_names;
in
{
  services.nginx = {
    defaultListen = [
      {
        addr = "0.0.0.0";
        ssl = false;
      }
      {
        addr = "[::]";
        ssl = false;
      }
      {
        addr = "127.0.0.1";
        ssl = true;
        proxyProtocol = true;
      }
      {
        addr = "[::1]";
        ssl = true;
        proxyProtocol = true;
      }
    ];
    virtualHosts = {
      "-" = {
        default = true;
        enableACME = false;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString k8s_http_port}";
        };
      };
    };
    defaultSSLListenPort = local_https_port;
    streamConfig = ''
      map $ssl_preread_server_name $name {
        ${ssl_server_name_map}
        default default;
      }
      ${upstream_map}
      upstream default {
        server 127.0.0.1:${toString k8s_https_port};
      }
      server {
        listen 443;
        listen [::]:443;
        ssl_preread on;
        proxy_pass $name;
        proxy_protocol on;
      }
    '';
  };
}
