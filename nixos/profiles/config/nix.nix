{ self, inputs, ... }:
{
  nix.settings = {
    min-free = 1024 * 1024 * 1024; # bytes
    auto-optimise-store = true;

    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "auto-allocate-uids"
      "cgroups"
    ];

    sandbox = true;
    use-cgroups = true;

    allowed-users = [ "@users" ];
    trusted-users = [
      "root"
      "@wheel"
    ];

    keep-outputs = true;
    keep-derivations = true;

    use-xdg-base-directories = true;
  };
}
