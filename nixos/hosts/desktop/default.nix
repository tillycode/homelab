{ suites, pkgs, ... }:
{
  imports = [ ./hardware.nix ] ++ suites.desktop;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  boot.loader.systemd-boot.memtest86.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # boot.kernelParams = [
  #   "intel_iommu=on"
  #   "iommu=pt"
  # ];
  # boot.kernelModules = [
  #   "vfio"
  #   "vfio_iommu_type1"
  #   "vfio_pci"
  #   "vfio_virqfd"
  #   "xhci_pci"
  # ];
  # boot.extraModprobeConfig = ''
  #   options vfio-pci ids=10de:1e84,10de:10f8,10de:1ad9
  # '';
  # boot.initrd.preDeviceCommands = ''
  #   DEVS="01:00.2"
  #   for DEV in $DEVS; do
  #       echo none > "/sys/bus/pci/devices/0000:$DEV/driver_override"
  #   done
  # '';
  #
  services.bird.enable = true;
  services.bird.config = ''
    log syslog all;

    protocol device {
    }

    protocol kernel {
      ipv4 {
        export all;
      };
    }

    protocol bgp {
      local 192.168.23.111 as 65000;
      neighbor 192.168.23.1 as 65001;
      ipv4 {
        import all;
        export all;
      };
    }
  '';

  networking.hosts = {
    "192.168.23.1" = [ "router" ];
    "10.9.0.11" = [ "hasee01" ];
    "10.9.0.12" = [ "hasee02" ];
    "10.9.0.13" = [ "hasee03" ];
  };
}
