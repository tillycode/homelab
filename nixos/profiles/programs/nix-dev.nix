{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    graphviz
    nix-du
    nix-melt
    nix-output-monitor
    nix-tree
    nixd
    nixfmt-rfc-style
    nvd
  ];
}
