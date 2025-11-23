{
  services.bird.enable = true;
  services.bird.config = ''
    log syslog all;

    protocol device {
    }

    protocol kernel {
      ipv4 {
        export all;
      };
    }

    protocol bgp {
      local 192.168.23.1 as 65001;
      neighbor 192.168.23.111 as 65000;
      ipv4 {
        import all;
        export all;
      };
      keepalive time 3;
      hold time 9;
      connect retry time 60;
    }
  '';
}
