{ config, ... }:
let
  domain = config.domains.blog;
in
{
  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      root = "/var/www/blog";
      index = "index.html";
      tryFiles = "$uri $uri/ /404.html";
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    "/var/www/blog"
  ];
}
