{ lib, ... }:
let
  modules = {
    nixago = ./nixago.nix;
  };
in
{
  flake.flakeModules = modules;
  imports = lib.attrValues modules;
}
