{
  services.frr = {
    bgpd.enable = true;
    config = ''
      router bgp 65122
       no bgp default ipv4-unicast
       neighbor 192.168.22.11 remote-as 65123
       neighbor 192.168.22.12 remote-as 65123
       neighbor 192.168.22.13 remote-as 65123
       !
       address-family ipv4 unicast
        neighbor 192.168.22.11 activate
        neighbor 192.168.22.12 activate
        neighbor 192.168.22.13 activate
        neighbor 192.168.22.11 route-map metalb-in in
        neighbor 192.168.22.12 route-map metalb-in in
        neighbor 192.168.22.13 route-map metalb-in in
        neighbor 192.168.22.11 soft-reconfiguration inbound
        neighbor 192.168.22.12 soft-reconfiguration inbound
        neighbor 192.168.22.13 soft-reconfiguration inbound
        neighbor 192.168.22.11 route-map metalb-out out
       exit-address-family
      exit
      !
      ip prefix-list metallb-ipv4 permit 10.41.0.0/16 le 32
      !
      route-map metalb-in permit 1
       match ip address prefix-list metallb-ipv4
      exit
    '';
  };

  # maximum-paths 3
  # bgp bestpath as-path multipath-relax
  boot.kernel.sysctl = {
    "net.ipv4.fib_multipath_hash_policy" = true;
  };

  networking.firewall.allowedTCPPorts = [ 179 ];

  services.tailscale.extraSetFlags = [
    "--advertise-routes"
    "10.41.0.0/16,192.168.22.10/32"
  ];
}
