{
  config,
  ...
}:
let
  zitadelResourceID = "300716890630651980";
  zitadelClientID = "300717015688085580";
  ipv4Address = "10.75.0.1";
  ipv4CIDR = "${ipv4Address}/24";
  ipv4RouteAdvertise = "10.75.0.0/24";
  httpsPort = config.ports.incus-https;
  domain = config.domains.incus;
  acmeDomain = config.domains.acme;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = "127.0.0.1:${toString httpsPort}";
        "oidc.audience" = zitadelResourceID;
        "oidc.client.id" = zitadelClientID;
        "oidc.issuer" = "https://login.szp15.com";
      };
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          project = "default";
          config = {
            "ipv4.address" = ipv4CIDR;
            "ipv6.address" = "auto";
            "ipv4.nat" = "true";
            "ipv6.nat" = "true";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "btrfs";
          description = "";
          config = {
            size = "30GiB";
          };
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              type = "nic";
              name = "eth0";
              network = "incusbr0";
            };
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
          };
        }
      ];
    };
  };

  ## ---------------------------------------------------------------------------
  ## LOCAL DNS
  ## ---------------------------------------------------------------------------
  systemd.network.networks."50-incusbr0" = {
    name = "incusbr0";
    linkConfig = {
      ActivationPolicy = "manual";
    };
    networkConfig = {
      DNS = ipv4Address;
      Domains = "~incus";
      KeepConfiguration = true;
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/incus";
      mode = "0711";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  ## ---------------------------------------------------------------------------
  ## ROUTE ADVERTISEMENT
  ## ---------------------------------------------------------------------------
  services.tailscale.extraSetFlags = [
    "--advertise-routes"
    ipv4RouteAdvertise
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://127.0.0.1:${toString httpsPort}";
      proxyWebsockets = true;
      extraConfig = ''
        allow 100.71.0.0/16;
        allow 10.75.0.0/16;
        deny all;
      '';
    };
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };
}
