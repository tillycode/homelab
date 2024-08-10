{
  suites,
  profiles,
  modulesPath,
  ...
}:
{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix") ]
    ++ suites.aliyun
    ++ (with profiles; [
      services.cluster.k3s-agent
      services.networking.caddy
      services.networking.headscale
      services.networking.headscale-caddy
    ]);

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ens5" ];
    externalInterface = "ens5";
  };

  system.stateVersion = "23.11";
}
