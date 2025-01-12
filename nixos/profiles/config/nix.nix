{
  nix.settings = {
    min-free = 1024 * 1024 * 1024; # 1GiB
    auto-optimise-store = true;
    experimental-features = [
      "auto-allocate-uids"
      "ca-derivations"
      "cgroups"
      "flakes"
      "nix-command"
    ];

    auto-allocate-uids = true;
    sandbox = true;
    use-cgroups = true;

    allowed-users = [ "@users" ];
    trusted-users = [ "@wheel" ];

    keep-outputs = true;

    use-xdg-base-directories = true;
  };
}
