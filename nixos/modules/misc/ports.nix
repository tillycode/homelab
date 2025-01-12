{ config, lib, ... }:
let
  ports = lib.attrValues config.ports;
  noCollision = l: lib.length (lib.unique l) == lib.length l;
in
{
  options.ports = lib.mkOption {
    type = with lib.types; attrsOf port;
    default = { };
  };

  config = {
    assertions = [
      {
        assertion = noCollision ports;
        message = "ports collision";
      }
    ];

    ports = {
      zitadel = 30000;

      netbird-signal = 10000;
      netbird-management = 33073;
      netbird-signal-metrics = 30010;
      netbird-management-metrics = 30011;
      # TODO: coturn ports

      headscale = 30020;
      headscale-metrics = 30021;

      incus-https = 30030;

      step-ca = 30040;

      homepage-dashboard = 30050;
    };
  };
}
