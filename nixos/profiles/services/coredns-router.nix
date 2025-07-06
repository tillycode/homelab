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
        forward . 172.18.0.2 /run/pppd/resolv.conf {
          policy sequential
        }
      }
    '';
  };

  ## ---------------------------------------------------------------------------
  ## FIREWALL
  ## ---------------------------------------------------------------------------
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
