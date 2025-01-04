{
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, config, ... }:
    let
      sources = pkgs.callPackages (import ./_sources/generated.nix) { };
    in
    {
      overlayAttrs = {
        inherit (config.packages)
          tailscale-patched
          headscale-ui
          hschip
          lego_4_21
          ;
      };
      packages = {
        tailscale-patched = pkgs.callPackage (import ./tailscale-patched) { };
        headscale-ui = inputs.dream2nix.lib.evalModules {
          packageSets.nixpkgs = pkgs;
          modules = [
            ./headscale-ui.nix
            {
              name = sources.headscale-ui.pname;
              version = sources.headscale-ui.version;
              mkDerivation.src = sources.headscale-ui.src;
            }
            {
              paths.projectRoot = ../.;
              paths.projectRootFile = "flake.nix";
              paths.package = ./.;
            }
          ];
        };
        hschip = pkgs.callPackage (import ./hschip) { };
      };
    };

  flake.overlays.hacks = final: prev: {
    dqlite = prev.dqlite.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ final.lz4.dev ];
    });

    lego_4_21 = final.lego.overrideAttrs rec {
      pname = "lego";
      version = "4.21.0";

      src = final.fetchFromGitHub {
        owner = "go-acme";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-3dSvQfkBNh8Bt10nv4xGplv4iY3gWvDu2EDN6UovSdc=";
      };
      vendorHash = "sha256-teA6fnKl4ATePOYL/zuemyiVy9jgsxikqmuQJwwA8wE=";

      ldflags = [
        "-s"
        "-w"
        "-X main.version=${version}"
      ];
    };

  };
}
