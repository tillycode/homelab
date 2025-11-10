let
  interface = "lan0";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.coredns = {
    enable = true;
    config = ''
      (snip) {
        bind ${interface}
        errors
        loadbalance
        loop
      }
      . {
        import snip
        forward . 192.168.1.1 {
          policy sequential
        }
      }
      k8s.szp.io {
        import snip
        forward . 10.41.0.10
      }
    '';
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
