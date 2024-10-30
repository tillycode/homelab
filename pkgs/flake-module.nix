{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    # let
    #   sources = pkgs.callPackages (import ./_sources/generated.nix) { };
    # in
    {
      overlayAttrs = {
        inherit (config.packages) tailscale-patched;
      };
      packages = {
        tailscale-patched = pkgs.callPackage (import ./tailscale-patched) { };
      };
    };
}
