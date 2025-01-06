{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # graphics application
    birdtray
    blueman
    chromium
    firefox
    # gimp-with-plugins
    evince
    font-manager
    file-roller
    gnome-disk-utility
    inkscape-with-extensions
    libqalculate
    pavucontrol
    qalculate-gtk
    remmina
    telegram-desktop
    thunderbird
    wireshark
    wpsoffice
    xclip
    xcolor
    xfce.catfish
    xfce.gigolo
    xfce.orage
    xfce.xfburn
    xfce.xfce4-appfinder
    xfce.xfce4-dict
    xorg.xkill
    vlc
    # xfce plugins
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-systemload-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-whiskermenu-plugin
    # games
    prismlauncher
    # man pages
    man-pages
    man-pages-posix
  ];

  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  services.pcscd.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.steam.enable = true;
  programs.steam.extraCompatPackages = with pkgs; [
    proton-ge-bin
  ];
}
