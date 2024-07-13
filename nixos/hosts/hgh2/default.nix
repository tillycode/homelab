{ profiles, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix") ]
    ++ (with profiles; [
      system.aliyun
      services.openssh
    ]);

  system.stateVersion = "23.11";
}
