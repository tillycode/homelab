{ suites, ... }:
{
  imports = [ ./hardware.nix ] ++ suites.desktop;
}
