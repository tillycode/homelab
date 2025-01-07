{ suites, pkgs, ... }:
{
  imports = [ ./hardware.nix ] ++ suites.desktop;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.open = false;
  hardware.nvidia-container-toolkit.enable = true;
}
