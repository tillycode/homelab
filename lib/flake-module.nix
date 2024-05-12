{ lib, ... }:
{
  flake.lib.data = lib.importJSON ./data/data.json;
}
