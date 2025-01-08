# Configure systemd-resolved
#
# Disable DNSSSEC, LLMNR and mDNS
{
  services.resolved = {
    dnssec = "false";
    llmnr = "false";
    extraConfig = ''
      MulticastDNS=off
    '';
  };
}
