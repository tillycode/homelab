{
  lib,
  pkgs,
  config,
  ...
}:
let
  generateYaml = (pkgs.formats.yaml { }).generate;
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  port = 25565;
  settings = {
    config = {
      bind = "[::]:${toString port}";
      lite = {
        enabled = true;
        routes = [
          {
            host = config.domains.mc;
            backend = config.domains.mc-internal;
            fallback = {
              motd = ''
                §cServer is offline :-(
                §ePlease contact Ziping Sun.
              '';
              version = {
                name = "§cTry again later!";
                protocol = -1;
              };

            };
            modifyVirtualHost = true;
          }
        ];
      };
    };
  };
in
{
  systemd.services.minecraft-gate = {
    description = "Minecraft Gate";
    wantedBy = [ "multi-user.target" ];
    script = ''
      exec ${lib.getExe pkgs.gate} -c ${generateYaml "config.yaml" settings}
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      DynamicUser = true;
    };
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ port ];

  ## ---------------------------------------------------------------------------
  ## MAP INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts."mc.szp15.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass =
      "http://${config.domains.mc-internal}:${toString config.ports.minecraft-dynmap}";
  };
}
