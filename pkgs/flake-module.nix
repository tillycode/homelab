{ ... }:
{
  flake.overlays.default =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      sources = final.callPackages (import ./_sources/generated.nix) { };
    in
    {
      kexec-installer-nixos-unstable-noninteractive =
        final.callPackage ./kexec-installer-nixos-unstable-noninteractive
          { source = sources."kexec-installer-nixos-unstable-noninteractive-${system}"; };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs) kexec-installer-nixos-unstable-noninteractive;
      };
    };
}
