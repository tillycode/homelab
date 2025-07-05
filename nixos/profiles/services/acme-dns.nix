{ config, ... }:
let
  domain = config.domains.acme-dns;
  acmeDomain = config.domains.acme;
  port = config.ports.acme-dns;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.acme-dns = {
    enable = true;
    settings = {
      general = {
        listen = "[::1]:${toString config.ports.acme-dns-dns}";
        protocol = "udp6";
        domain = "acme-dns";
        nsname = "acme-dns";
        nsadmin = "admin.acme-dns";
        records = [ ];
        debug = false;
      };
      database = {
        engine = "sqlite3";
        connection = "/var/lib/acme-dns/acme-dns.db";
      };
      api = {
        ip = "[::1]";
        port = port;
        tls = "none";
        disable_registration = false;
        corsorigins = [ ];
        use_header = true;
        header_name = "X-Forwarded-For";
      };
      logconfig = {
        loglevel = "info";
        logtype = "stdout";
        logformat = "text";
      };
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/acme-dns";
      mode = "0700";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
    };
    extraConfig = ''
      allow 100.120.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };
}
