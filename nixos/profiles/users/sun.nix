{ config, pkgs, ... }:
{
  sops.secrets."user-password/sun" = {
    neededForUsers = true;
    sopsFile = config.sops-file.common;
  };

  users.users.sun = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets."user-password/sun".path;
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  home-manager.users.sun = import ./_sunHome.nix;

  environment.persistence."/persist" = {
    users.sun.directories = [
      ".cache"
      ".config"
      ".local"
      ".npm"
      ".vscode"
      ".aws"
      ".aliyun"
      ".kube"
      "Documents"
      "Downloads"
      "Projects"
      {
        directory = ".ssh";
        mode = "0700";
      }
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ];
  };
}
