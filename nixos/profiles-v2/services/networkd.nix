# Use systemd-networkd as network manager
{
  networking.useNetworkd = true;
  networking.useDHCP = false;

  systemd.network.networks = {
    "50-wlan" = {
      name = "wl*";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
    };
    "50-enther" = {
      name = "en*";
      DHCP = "yes";
    };
  };
  systemd.network.wait-online.anyInterface = true;
}
