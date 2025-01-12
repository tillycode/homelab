{ pkgs, ... }:
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

    home  CNAME hgh1.ts.szp.io.
    acme  IN CNAME hgh1.ts.szp.io.
    incus IN CNAME desktop.ts.szp.io.
    cache IN CNAME hgh0.ts.szp.io.
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
    '';
  };
  systemd.services.coredns.preStart = ''
    until [[ -n "$(${pkgs.iproute2}/bin/ip -br address show up scope global dev ${interface} 2>/dev/null)" ]]; do
      sleep 1
    done
  '';
}
