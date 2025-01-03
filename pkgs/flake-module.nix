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
        inherit (config.packages) tailscale-patched headscale-ui hschip;
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

  flake.overlays.fix-lxd = final: prev: {
    dqlite = prev.dqlite.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ final.lz4.dev ];
    });
  };
}
