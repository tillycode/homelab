{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    binutils
    coreutils
    dig
    dust
    ethtool
    fd
    file
    htop
    iptables
    jq
    lsof
    nettools
    nftables
    openssl
    p7zip
    pciutils
    ripgrep
    strace
    tcpdump
    unzip
    usbutils
    util-linux
    yq-go
  ];
}
