{ suites, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ] ++ suites.aliyunServer;

  system.stateVersion = "23.11";
}
