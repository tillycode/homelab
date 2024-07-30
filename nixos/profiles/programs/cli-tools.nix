{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bat
    binutils
    coreutils
    dust
    eza
    fd
    file
    htop
    jq
    openssl
    p7zip
    pciutils
    ripgrep
    unzip
    usbutils
    util-linux
    yq-go
    zoxide
  ];
}
