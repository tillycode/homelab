{ pkgs, ... }:
let
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

    @ IN NS ns.svc.szp.io.
    ns IN A 100.71.0.1

    lxd IN CNAME desktop.ts.szp.io.
  '';
in
{
  services.coredns = {
    enable = true;
    config = ''
      (snip) {
        bind tailscale0
        log
        errors
      }
      ts.szp.io:53 {
        import snip
        forward . 100.100.100.100
        cache 300
      }
      vm.szp.io:53 {
        import snip
        forward . 10.75.0.1
        cache 300
        rewrite name suffix .vm.szp.io .lxd answer auto
      }
      svc.szp.io:53 {
        import snip
        file ${zone}
        cache 300
      }
    '';
  };
}
