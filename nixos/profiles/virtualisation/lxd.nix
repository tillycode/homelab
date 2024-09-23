{
  virtualisation.lxd.enable = true;
  virtualisation.lxd.recommendedSysctlSettings = true;
  virtualisation.lxd.ui.enable = true;

  users.users.sun.extraGroups = [ "lxd" ];

  systemd.network.networks."10-lxdbr0" = {
    name = "lxdbr0";
    linkConfig = {
      ActivationPolicy = "manual";
    };
    networkConfig = {
      DNS = "10.212.4.1";
      Domains = "~lxd";
      KeepConfiguration = true;
    };
  };
}
