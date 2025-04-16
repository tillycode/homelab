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
          terraboard
          sing-box_1_12
          github-actions-cache-server
          github-runner-patched
          ;
      };
      packages = {
        tailscale-patched = pkgs.callPackage (import ./tailscale-patched) { };
        github-runner-patched = pkgs.callPackage (import ./github-runner-patched) { };
        terraboard = pkgs.callPackage (import ./terraboard) {
          source = sources.terraboard;
        };
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
        sing-box_1_12 = pkgs.sing-box.overrideAttrs (oldAttrs: rec {
          inherit (sources.sing-box)
            pname
            version
            src
            vendorHash
            ;
          tags = oldAttrs.tags ++ [ "with_tailscale" ];
          ldflags = "-X=github.com/sagernet/sing-box/constant.Version=${version}";
        });
        attic-client_patched = pkgs.attic-client.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [ ./attic-client-graceful-shutdown.patch ];
        });
        github-actions-cache-server = pkgs.callPackage (import ./github-actions-cache-server.nix) {
          source = sources.github-actions-cache-server;
        };
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
