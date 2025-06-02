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
      zitadel = 40000;

      netbird-signal = 10000;
      netbird-management = 40012;
      netbird-signal-metrics = 40010;
      netbird-management-metrics = 40011;
      # TODO: coturn ports

      headscale = 40020;
      headscale-metrics = 40021;

      incus-https = 40030;

      step-ca = 40040;
      step-ca-metrics = 40041;

      homepage-dashboard = 40050;

      atticd = 40060;

      terraboard = 40070;
      terraboard-swagger = 40071;

      oauth2-proxy = 40080;

      gha-cache-server = 40090;

      xray-nginx-https = 40100;

      # headscale-global = 40110;

      minio = 40120;
      minio-console = 40121;

      acme-dns = 40130;
      acme-dns-dns = 40131;

      prometheus = 40140;

      node-exporter = 40150;

      grafana = 40160;

      coredns-metrics = 40170;

      loki = 40180;
      loki-grpc = 40181;

      cloudreve = 40190;

      aria2-rpc = 40200;

      minecraft-dynmap = 40210;

      rke2-ingress-http = 40220;
      rke2-ingress-https = 40221;
    };
  };
}
