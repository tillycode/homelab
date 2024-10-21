{ lib, inputs, ... }:
{
  flake.lib = import ../lib { inherit lib inputs; };
}
