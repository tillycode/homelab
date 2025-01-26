{ suites, pkgs, ... }:
{
  imports = [ ./hardware.nix ] ++ suites.desktop;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.open = false;
  # hardware.nvidia-container-toolkit.enable = true;

  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];
  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "xhci_pci"
  ];
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:1e84,10de:10f8,10de:1ad9
  '';
  boot.initrd.preDeviceCommands = ''
    DEVS="01:00.2"
    for DEV in $DEVS; do
        echo none > "/sys/bus/pci/devices/0000:$DEV/driver_override"
    done
  '';
}
