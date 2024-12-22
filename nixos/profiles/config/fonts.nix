{ pkgs, ... }:
{
  fonts.enableDefaultPackages = false;
  fonts.packages =
    (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      # jetbrains-mono
    ])
    ++ (with pkgs.nerd-fonts; [
      jetbrains-mono
      roboto-mono
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
    monospace = [ "JetBrains Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
  fonts.fontDir.enable = true;
}
