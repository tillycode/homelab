{ config, ... }:
{
  services.nginx.defaultListen = [
    {
      addr = "0.0.0.0";
      ssl = false;
    }
    {
      addr = "[::]";
      ssl = false;
    }
    {
      addr = "127.0.0.1";
      ssl = true;
      proxyProtocol = true;
    }
    {
      addr = "[::1]";
      ssl = true;
      proxyProtocol = true;
    }
  ];
  services.nginx.defaultSSLListenPort = config.ports.xray-nginx-https;
  services.nginx.commonHttpConfig = ''
    set_real_ip_from 127.0.0.1;
    set_real_ip_from ::1;
    real_ip_header proxy_protocol;
  '';
}
