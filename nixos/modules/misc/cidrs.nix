{ lib, ... }:
{
  options = {
    CIDRs = lib.mkOption {
      type = with lib.types; lazyAttrsOf str;
      default = { };
    };
    IPs = lib.mkOption {
      type = with lib.types; lazyAttrsOf str;
      default = { };
    };
  };

  config = {
    CIDRs = {
      tailnet-v4 = "100.71.0.0/16";
      tailnet-v6 = "fd7a:115c:a1e0:7::/64";

      tailnet-global-v4 = "100.72.0.0/16";
      tailnet-global-v6 = "fd7a:115c:a1e0:8::/64";

      incus-v4 = "10.75.0.0/16";
      incus-v6 = "fd42:e16c:cbc4::/48";

      sing-box-tun-v4 = "172.18.0.1/30";
      sing-box-tun-v6 = "fdfe:dcba:9876::1/126";

      sing-box-fakeip-v4 = "198.18.0.0/15";
      sing-box-fakeip-v6 = "fc00::/18";
    };

    IPs = {
      coredns = "100.71.0.1";
      coredns-global = "100.72.0.1";
      sing-box-dns-v4 = "172.18.0.2";
      sing-box-dns-v6 = "fdfe:dcba:9876::2";
    };
  };
}
