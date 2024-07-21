{ config, ... }:
{
  services.sing-box-client = {
    enable = true;
    enableClashApi = true;
    outboundsFile = config.sops.secrets."sing-box/outbounds.json".path;
    dnsRules = [
      {
        ip_is_private = true;
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
    sopsFile = config.sops-file.common;
  };
}
