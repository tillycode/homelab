{ pkgs, config, ... }:
let
  interface = "tailscale0";
  # TODO: use nix to manage CNAMEs
  zone = pkgs.writeText "zonefile" ''
    $ORIGIN svc.szp.io.
    $TTL 3600

    @ IN SOA ns.svc.szp.io. me.szp.io. (
      2025010101 ; serial
      3600       ; refresh
      1800       ; retry
      604800     ; expire
      3600       ; minimum
    )

    @     IN NS ns.svc.szp.io.
    ns    IN A 100.71.0.1

    home                  IN CNAME hgh2.ts.szp.io.
    acme                  IN CNAME hgh2.ts.szp.io.
    incus                 IN CNAME desktop.ts.szp.io.
    gha-cache             IN CNAME desktop.ts.szp.io.
    minio                 IN CNAME desktop.ts.szp.io.
    *.minio               IN CNAME minio.svc.szp.io.
    _acme-challenge.minio IN CNAME 47f2e892-8271-443a-a9c7-43c14873b066.acme-challenge.svc.szp.io.
    acme-dns              IN CNAME hgh2.ts.szp.io.
    prometheus            IN CNAME hgh2.ts.szp.io.
    grafana               IN CNAME hgh2.ts.szp.io.
  '';
in
{
  services.coredns = {
    enable = true;
    config = ''
      (snip) {
        bind ${interface}
        log
        errors
        prometheus [::]:${toString config.ports.coredns-metrics}
      }
      ts.szp.io:53 {
        import snip
        forward . 100.100.100.100
        cache 60
      }
      vm.szp.io:53 {
        import snip
        forward . 10.75.0.1
        cache 60
        rewrite name suffix .vm.szp.io .incus answer auto
      }
      svc.szp.io:53 {
        import snip
        file ${zone}
        cache 60
      }
      acme-challenge.svc.szp.io:53 {
        import snip
        forward . [::1]:${toString config.ports.acme-dns-dns}
        cache 5
        rewrite name suffix .acme-challenge.svc.szp.io .acme-dns answer auto
      }
    '';
  };
  systemd.services.coredns.preStart = ''
    until [[ -n "$(${pkgs.iproute2}/bin/ip -br address show up scope global dev ${interface} 2>/dev/null)" ]]; do
      sleep 1
    done
  '';
}
