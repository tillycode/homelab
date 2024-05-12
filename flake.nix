{
  description = "Ziping Sun's NixOS configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # flake modules
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/flake-module.nix
        ./lib/flake-module.nix
        ./pkgs/flake-module.nix
      ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
}
