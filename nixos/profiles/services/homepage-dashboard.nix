{ config, pkgs, ... }:
let
  domain = config.domains.homepage-dashboard;
  acmeDomain = config.domains.acme;

  background = pkgs.fetchurl {
    name = "homepage-background.jpeg";
    # background image in the official documentation
    url = "https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fm=jpg&fit=crop&w=2560&q=80";
    hash = "sha256-ixg2MEbI/0tvJXAQ9V2JB9yyiUrOPgIE5QNtpahIIQE=";
  };
  package = pkgs.homepage-dashboard.overrideAttrs (oldAttrs: {
    postInstall = ''
      mkdir -p $out/share/homepage/public/images
      ln -s ${background} $out/share/homepage/public/images/background.jpeg
    '';
  });
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.homepage-dashboard = {
    enable = true;
    listenPort = config.ports.homepage-dashboard;
    package = package;
    settings = {
      title = "Sun's Homelab";
      description = "A homepage dashboard for my homelab.";
      background = "/images/background.jpeg";
      cardBlur = "sm";
      hideVersion = true;
      layout = {
        Links = {
          style = "row";
          columns = 4;
        };

      };
    };
    bookmarks = [
      {
        Links = [
          {
            GitHub = [
              {
                abbr = "GH";
                href = "https://github.com/tillycode/homelab";
              }
            ];
          }
          {
            "Alibaba Cloud" = [
              {
                abbr = "AY";
                href = "https://home.console.aliyun.com/home/dashboard/ProductAndService";
              }
            ];
          }
          {
            AWS = [
              {
                abbr = "AW";
                href = "https://console.aws.amazon.com/console/home";
              }
            ];
          }
          {
            "Tencent Cloud" = [
              {
                abbr = "TC";
                href = "https://console.cloud.tencent.com/";
              }
            ];
          }
          {
            "Misaka" = [
              {
                abbr = "MS";
                href = "https://app.misaka.io/";
              }
            ];
          }
        ];
      }
    ];
    services = [
      {
        IPA = [
          {
            Zitadel = {
              href = "https://${config.domains.zitadel}";
              description = "Identity Provider";
              siteMonitor = "https://${config.domains.zitadel}/.well-known/openid-configuration";
            };
          }
          {
            "Step CA" = {
              href = "https://${config.domains.step-ca}/acme/acme/directory";
              description = "Certificate Authority";
              siteMonitor = "https://${config.domains.step-ca}/acme/acme/directory";
            };
          }
        ];
      }
      {
        Networks = [
          {
            Headscale = {
              href = "https://${config.domains.tailnet}";
              description = "Tailscale Network";
            };
          }
        ];
      }
      {
        Virtualization = [
          {
            Incus = {
              href = "https://${config.domains.incus}";
              description = "System container and VM manager";
            };
          }
        ];
      }
      {
        "CI/CD" = [
          {
            Attic = {
              href = "https://${config.domains.atticd}";
              description = "Binary Cache";
            };
          }
          {
            "GHA Cache Server" = {
              href = "https://${config.domains.gha-cache-server}";
              description = "GitHub Actions Cache Server";
              siteMonitor = "https://${config.domains.gha-cache-server}";
            };
          }
        ];
      }
    ];
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.homepage-dashboard}";
      proxyWebsockets = true;
      extraConfig = ''
        allow 100.71.0.0/16;
        allow fd7a:115c:a1e0:7::/64;
        allow 10.75.0.0/16;
        allow fd42:e16c:cbc4::/48;
        deny all;
      '';
    };
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };
}
