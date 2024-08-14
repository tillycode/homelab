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
      services.cluster.k3s-common
    ]);

  system.stateVersion = "23.11";
}
