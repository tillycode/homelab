{ pkgs, ... }:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerSocket.enable = true;
    dockerCompat = true;
  };
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "btrfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };

  ## ---------------------------------------------------------------------------
  ## CLI
  ## ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [ docker-compose ];

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    "/var/lib/containers"
  ];
}
