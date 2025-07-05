{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    juicefs
  ];

  fileSystems."jfs" = {
    # device = "redis://master,192.168.22.10,192.168.22.11,192.168.22.12:26379";
    device = "tikv://192.168.22.10:2379,192.168.22.11:2379,192.168.22.12:2379/jfs";
    mountPoint = "/jfs";
    fsType = "juicefs";
    noCheck = true;
    options = [
      "_netdev"
      "allow_other"
      "writeback"
    ];
  };

  environment.persistence.default.directories = [
    {
      directory = "/var/jfsCache";
      mode = "0700";
    }
  ];

  programs.nix-ld.enable = true; # for TiKV
}
