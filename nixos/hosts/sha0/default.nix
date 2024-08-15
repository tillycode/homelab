{
  suites,
  profiles,
  modulesPath,
  ...
}:
{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix") ]
    ++ suites.domestic
    ++ (with profiles; [
      system.disk.tencent
      services.cluster.k3s-agent
      services.cluster.k3s-common
    ]);

  system.stateVersion = "23.11";
}
