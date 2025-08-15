{ pkgs, config, ... }:
{
  services.sing-box = {
    enable = true;
    enableCustom = true;
    package = pkgs.sing-box_1_12;
    # outboundsFile = config.sops.secrets."sing-box/outbounds.json".path;
    dnsRules = [
      {
        domain_suffix = [
          "k8s.szp.io"
        ];
        action = "route";
        server = "local-router";
      }
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
        action = "route";
        server = "local";
      }
      {
        ip_is_private = true;
        action = "route";
        server = "local";
      }
      {
        domain_suffix = [
          # steam CDNs
          "steamcontent.com"
          "steamcontent.akadns.net"
          "steamserver.net"
          # Aliyun
          "aliyuncs.com"
          # GNUPG
          "keys.openpgp.org"
          # My Websites
          "szp15.com"
          "eh578599.xyz"
        ];
        server = "local";
      }
      {
        domain_suffix = [
          "byr.pt"
        ];
        server = "proxy";
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
        action = "route";
        ip_cidr = [
          "100.121.0.0/16"
        ];
        outbound = "proxy";
      }
      {
        action = "sniff";
      }
      {
        action = "hijack-dns";
        protocol = "dns";
      }
      {
        action = "route";
        rule_set = "geosite-openai";
        outbound = "us";
      }
    ];
    geoipRuleSet = [ "geoip-cn" ];
    geositeRuleSet = [
      "geosite-openai"
      "geosite-geolocation-cn"
    ];
    outboundsFile = config.sops.secrets."sing-box/outbounds.json".path;
    tunExtraRoutes = [
      "100.121.0.0/16"
    ];
  };

  sops.secrets."sing-box/outbounds.json" = { };
}
