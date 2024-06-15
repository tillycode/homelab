{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      _ = pkgs.callPackages (import ./_sources/generated.nix) { };
    in
    {
      overlayAttrs = {
        inherit (config.packages);
      };
      packages = { };
    };
}
