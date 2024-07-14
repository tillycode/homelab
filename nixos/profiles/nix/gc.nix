{
  nix.gc = {
    automatic = true;
    options = "--elete-older-than 2d";
  };
  nix.settings.min-free = 1024 * 1024 * 1024; # bytes
}
