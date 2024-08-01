{ pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
    };
    containers.storage.settings = {
      storage = {
        driver = "btrfs";
        graphroot = "/var/lib/containers/storage";
        runroot = "/run/containers/storage";
      };
    };
  };

  environment.systemPackages = with pkgs; [ docker-compose ];
}
