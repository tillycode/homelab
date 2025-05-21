{ lib, ... }:
{
  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  systemd.network.networks = {
    "10-eno1" = {
      name = "eno1";
      address = [ "192.168.27.1/24" ];
      networkConfig = {
        DHCPServer = "yes";
        IPMasquerade = "ipv4";
      };
      dhcpServerConfig = {
        EmitDNS = "yes";
        EmitTimezone = "no";
        PoolOffset = 100;
        PoolSize = 1;
      };
    };
  };
  services.sing-box.settings.route = {
    auto_detect_interface = lib.mkForce false;
    default_interface = "wlan0";
  };
  networking.firewall.trustedInterfaces = [ "eno1" ];
}
