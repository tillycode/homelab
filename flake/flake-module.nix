{ ... }:
{
  imports = [
    ./devshell
    ./legacy-packages.nix
    ./nixpkgs.nix
    ./hosts.nix
    ./flake-lib.nix
  ];
}
