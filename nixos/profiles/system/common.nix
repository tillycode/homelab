{
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "C.UTF-8";

  security.sudo = {
    extraConfig = ''
      Defaults lecture="never"
    '';
    wheelNeedsPassword = false;
  };

  environment.persistence."/persist" = {
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    directories = [
      "/var/lib"
      "/var/log"
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
