{ config, ... }:
let
  domain = config.domains.oauth2-proxy;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://login.szp15.com";
    email.domains = [ "*" ];
    httpAddress = "http://127.0.0.1:${toString config.ports.oauth2-proxy}";
    reverseProxy = true;
    keyFile = config.sops.templates."oauth2-proxy/config.env".path;
    extraConfig = {
      code-challenge-method = "S256";
      whitelist-domain = [
        "*.svc.szp.io"
        "login.szp15.com"
      ];
    };
    nginx.domain = domain;
    cookie.domain = ".svc.szp.io";
    cookie.refresh = "30m";
    setXauthrequest = true;
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."oauth2-proxy/clientId" = { };
  sops.secrets."oauth2-proxy/clientSecret" = { };
  sops.secrets."oauth2-proxy/cookieSecret" = { };
  sops.templates."oauth2-proxy/config.env" = {
    content = ''
      OAUTH2_PROXY_CLIENT_ID=${config.sops.placeholder."oauth2-proxy/clientId"}
      OAUTH2_PROXY_CLIENT_SECRET=${config.sops.placeholder."oauth2-proxy/clientSecret"}
      OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder."oauth2-proxy/cookieSecret"}
    '';
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      allow 100.71.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs."${domain}" = {
    server = "https://${config.domains.acme}/acme/acme/directory";
  };
}
