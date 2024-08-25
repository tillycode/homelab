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
      services.cluster.k3s-ingress
      services.networking.nginx
      services.networking.tailscale-derper
    ]);

  system.stateVersion = "23.11";
}
