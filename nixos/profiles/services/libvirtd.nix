{
  virtualisation.libvirtd = {
    enable = true;
  };

  environment.persistence.default.directories = [
    {
      directory = "/var/lib/libvirt";
      mode = "0755";
    }
  ];
  networking.firewall.trustedInterfaces = [ "virbr*" ];
}
