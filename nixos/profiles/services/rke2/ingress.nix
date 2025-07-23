{ config, ... }:
{
  services.nginx.enableSNIProxy = true;
  services.nginx.sniHosts."rke2-ingress" = {
    serverNames = [ ];
    default = true;
    servers = {
      "127.0.0.1:${toString config.ports.rke2-ingress-https}" = { };
    };
  };
  services.nginx.virtualHosts = {
    "rke2-ingress" = {
      serverName = "\"\"";
      default = true;
      enableACME = false;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.ports.rke2-ingress-http}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 0;
        '';
      };
    };
  };
}
