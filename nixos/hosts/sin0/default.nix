{ suites, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ] ++ suites.misaka;

  system.stateVersion = "23.11";
}
