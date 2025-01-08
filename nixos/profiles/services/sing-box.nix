{ config, ... }:
{
  services.sing-box-client = {
    enable = true;
    outboundsFile = config.sops.secrets."sing-box/outbounds.json".path;
    dnsRules = [
      {
        # This is a trick to make sing-box return NXDOMAIN for a non-existent
        # domain instead of returning a FakeIP.
        #
        # In sing-box, all destination CIDR rules won't match a DNS query for
        # a non-existent domain. This causes the default rule to be used.
        # In our case, the default rule is a FakeIP.
        #
        # By adding an invert rule that matches any existing domain, we can
        # let sing-box return NXDOMAIN for a non-existent domain.
        ip_cidr = [
          "0.0.0.0/0"
          "::/0"
        ];
        invert = true;
        server = "local";
      }
      {
        ip_is_private = true;
        server = "local";
      }
      {
        # steam CDNs
        domain_suffix = [
          "steamcontent.com"
          "steamcontent.akadns.net"
          "steamserver.net"
        ];
        server = "local";
      }
      {
        rule_set = [
          "geoip-cn"
          "geosite-geolocation-cn"
        ];
        server = "local";
      }
    ];
    routeRules = [
      {
        rule_set = "geosite-openai";
        outbound = "us";
      }
    ];
    geoipRuleSet = [ "geoip-cn" ];
    geositeRuleSet = [
      "geosite-openai"
      "geosite-geolocation-cn"
    ];
  };

  sops.secrets."sing-box/outbounds.json" = {
    restartUnits = [ "sing-box-client.service" ];
  };
}
