{ config, ... }:
{
  services.hydra = {
    enable = true;
    port = config.ports.hydra;
    hydraURL = "https://${config.domains.hydra}";
    useSubstitutes = true;
    notificationSender = "me@szp.io";
  };

  environment.persistence.default.directories = [
    {
      directory = "/var/lib/hydra";
      user = "hydra";
      group = "hydra";
      mode = "0700";
    }
  ];

  services.nginx.virtualHosts.${config.domains.hydra} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.hydra}";
      extraConfig = ''
        proxy_set_header X-Request-Base /;
        allow 100.120.0.0/16;
        allow fd7a:115c:a1e0:7::/64;
        allow 10.75.0.0/16;
        allow fd42:e16c:cbc4::/48;
        deny all;
      '';
    };
  };
  security.acme.certs."${config.domains.hydra}" = {
    server = "https://${config.domains.acme}/acme/acme/directory";
  };

  nix.settings.allowed-users = [
    "hydra"
    "hydra-queue-runner"
    "hydra-www"
  ];
}
