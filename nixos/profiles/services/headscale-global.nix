{ pkgs, config, ... }:
{
  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${config.domains.tailnet-global} = {
    enableACME = true;
    forceSSL = true;
    locations."/web/" = {
      alias = "${pkgs.headscale-ui}/";
      tryFiles = "$uri $uri/index.html =404";
    };
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.headscale-global}";
      proxyWebsockets = true;
    };
    locations."= /" = {
      return = "301 $scheme://$host/web/";
    };
  };
}
