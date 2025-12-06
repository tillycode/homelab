{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  virtualisation.incus = {
    enable = true;
    # preseed = {
    #   config = {
    #     "core.https_address" = "${ip}:8443";
    #   };
    #   networks = [ ];
    #   storage_pools = [
    #     {
    #       name = "local";
    #       driver = "btrfs";
    #       config = {
    #         source = "/var/lib/incus/storage-pools/local";
    #       };
    #     }
    #   ];
    #   storage_volumes = [ ];
    #   profiles = [
    #     {
    #       name = "default";
    #       project = "default";
    #       devices = {
    #         root = {
    #           type = "disk";
    #           path = "/";
    #           pool = "local";
    #         };
    #       };
    #     }
    #   ];
    #   projects = [ ];
    #   certificates = [ ];
    #   cluster = {
    #     server_name = server_name;
    #     enabled = true;
    #     member_config = [ ];
    #     # cluster_address = "";
    #     # cluster_certificate = "";
    #     # server_address = "";
    #     # cluster_token = "";
    #     # cluster_certificate_path = "";
    #   };
    # };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/incus";
      mode = "0711";
    }
  ];
}
