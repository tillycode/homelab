{ suites, ... }:
{
  imports = [ ./hardware.nix ] ++ suites.desktop;

  system.stateVersion = "23.11";
}
