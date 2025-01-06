{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ## network
    ethtool
    iptables
    nftables
    dnsutils
    openssl
    tcpdump
    mtr

    ## data processing
    jq
    yq-go

    ## system management
    file
    htop
    lsof
    killall
    binutils
    pciutils
    usbutils

    ## compression
    unzip
    p7zip

    ## RIIR tools
    ripgrep
    fd
    dust
    bandwhich
    sd
    tokei
    miniserve
    tealdeer
    nushell
  ];
}
