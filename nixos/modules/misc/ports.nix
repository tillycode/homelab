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
      step-ca-metrics = 30041;

      homepage-dashboard = 30050;

      atticd = 30060;

      terraboard = 30070;
      terraboard-swagger = 30071;

      oauth2-proxy = 30080;

      gha-cache-server = 30090;

      xray-nginx-https = 30100;

      # headscale-global = 30110;

      minio = 30120;
      minio-console = 30121;

      acme-dns = 30130;
      acme-dns-dns = 30131;

      prometheus = 30140;

      node-exporter = 30150;

      grafana = 30160;

      coredns-metrics = 30170;

      loki = 30180;
      loki-grpc = 30181;

      cloudreve = 30190;

      aria2-rpc = 30200;

      minecraft-dynmap = 30210;

      rke2-ingress-http = 30220;
      rke2-ingress-https = 30221;
    };
  };
}
