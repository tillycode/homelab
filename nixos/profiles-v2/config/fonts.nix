{ pkgs, ... }:
{
  fonts.enableDefaultPackages = false;
  fonts.packages =
    (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ])
    ++ (with pkgs.nerd-fonts; [
      jetbrains-mono
    ]);
  fonts.fontconfig.defaultFonts = {
    serif = [
      "Noto Serif"
      "Noto Serif CJK SC"
    ];
    sansSerif = [
      "Noto Sans"
      "Noto Sans CJK SC"
    ];
    monospace = [ "JetBrainsMono Nerd Font Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
  fonts.fontDir.enable = true;
}
