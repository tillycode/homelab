{
  description = "Ziping Sun's NixOS configuration";

  nixConfig.extra-substituters = [ "https://sunziping2016.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "sunziping2016.cachix.org-1:7g2G+myu9428IcIKO83W9efXq+uGR1u4C3LR//yVpUc="
  ];

  inputs = {
    # nixpkgs

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # flake modules

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.flake-compat.follows = "flake-compat";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.inputs.gitignore.follows = "gitignore-nix";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.flake-compat.follows = "flake-compat";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    # libraries

    nixago.url = "github:jmgilman/nixago";
    nixago.inputs.nixpkgs.follows = "nixpkgs";
    nixago.inputs.flake-utils.follows = "flake-utils";
    nixago.inputs.nixago-exts.follows = "nixago-exts";

    nixago-exts.url = "github:nix-community/nixago-extensions";
    nixago-exts.inputs.flake-utils.follows = "flake-utils";
    nixago-exts.inputs.nixago.follows = "nixago";
    nixago-exts.inputs.nixpkgs.follows = "nixpkgs";

    # nixos modules

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # home-manger modules

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.inputs.flake-utils.follows = "flake-utils";

    # libraries

    blank.url = "github:divnix/blank";

    systems.url = "github:nix-systems/default";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    haumea.url = "github:nix-community/haumea";
    haumea.inputs.nixpkgs.follows = "nixpkgs";

    gitignore-nix.url = "github:hercules-ci/gitignore.nix";
    gitignore-nix.inputs.nixpkgs.follows = "nixpkgs";

    pyproject-nix.url = "github:nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

    nv2nix.url = "github:adisbladis/uv2nix";
    nv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    nv2nix.inputs.nixpkgs.follows = "nixpkgs";

    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.inputs.purescript-overlay.follows = "blank";
    dream2nix.inputs.pyproject-nix.follows = "blank";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        flake-parts.flakeModules.easyOverlay

        ./flake-modules/flake-module.nix
        ./flake/flake-module.nix
        ./pkgs/flake-module.nix
      ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
}
