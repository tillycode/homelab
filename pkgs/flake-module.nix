{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      sources = pkgs.callPackages (import ./_sources/generated.nix) { };
    in
    {
      overlayAttrs = {
        inherit (config.packages) headscale-beta;
      };
      packages = {
        headscale-beta = pkgs.callPackage (import ./headscale-beta) { inherit sources; };
      };
    };
}
