{ suites, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ] ++ suites.aliyun;

  system.stateVersion = "23.11";
}
