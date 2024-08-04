{
  services.caddy.virtualHosts."headscale.szp15.com".extraConfig = ''
    reverse_proxy http://127.0.0.1:8080
  '';
}
