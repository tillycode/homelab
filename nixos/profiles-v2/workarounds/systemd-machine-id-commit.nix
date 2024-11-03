# See nix-community/impermanence#229 and NixOS/nixpkgs#351151
{
  boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
