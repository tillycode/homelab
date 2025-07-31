{
  lib,
  callPackage,
  nixpkgs,
  ...
}@args:
let
  common =
    opts:
    callPackage (import "${nixpkgs}/pkgs/applications/networking/cluster/rke2/builder.nix" lib opts);
  extraArgs = builtins.removeAttrs args [
    "callPackage"
    "nixpkgs"
  ];
in
{
  rke2_1_32 = common (
    (import ./1_32/versions.nix)
    // {
      updateScript = [
        ./update-script.sh
        "32"
      ];
    }
  ) extraArgs;
  rke2_1_33 = common (
    (import ./1_33/versions.nix)
    // {
      updateScript = [
        ./update-script.sh
        "33"
      ];
    }
  ) extraArgs;
}
