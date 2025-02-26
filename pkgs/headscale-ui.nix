{
  dream2nix,
  config,
  lib,
  ...
}:
{
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-lock-v3
    dream2nix.modules.dream2nix.nodejs-granular-v3
  ];

  deps =
    { nixpkgs, ... }:
    {
      inherit (nixpkgs)
        fetchFromGitHub
        stdenv
        ;
    };

  # don't install node-modules
  mkDerivation.preInstallPhases = lib.mkForce [ ];
  mkDerivation.installPhase = ''
    echo "executing installPhase"
    mkdir -p $out
    cp -r build/* $out
  '';

  # Hacks
  nodejs-package-lock-v3 = {
    packageLockFile = "${config.mkDerivation.src}/package-lock.json";
    # TODO: record bugs
    pdefs.headscale-ui."2024.10.10".dependencies = {
      "vite" = {
        dev = true;
        version = "5.4.11";
      };
    };
  };
}
