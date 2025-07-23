{ lib, ... }:
let
  manifests = lib.pipe ./_manifests [
    builtins.readDir
    (lib.filterAttrs (k: v: v == "regular" && lib.hasSuffix ".yaml" k))
    (lib.mapAttrs (k: v: builtins.readFile ./_manifests/${k}))
  ];
in
{
  imports = [
    ./_common.nix
  ];
  services.rke2 = {
    role = "server";
    inherit manifests;
  };
}
