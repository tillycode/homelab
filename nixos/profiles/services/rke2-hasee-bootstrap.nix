{ lib, ... }:
let
  manifests = lib.pipe ./_rke2-manifests [
    builtins.readDir
    (lib.filterAttrs (k: v: v == "regular" && lib.hasSuffix ".yaml" k))
    (lib.mapAttrs (k: v: builtins.readFile ./_rke2-manifests/${k}))
  ];
in
{
  imports = [
    ./_rke2-common.nix
  ];
  services.rke2 = {
    role = "server";
    inherit manifests;
  };
}
