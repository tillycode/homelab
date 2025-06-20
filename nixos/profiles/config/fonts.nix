{ pkgs, ... }:
{
  fonts.packages = (
    with pkgs;
    [
      source-serif
      source-sans
      source-han-serif
      source-han-sans

      liberation_ttf
      wqy_zenhei
      wqy_microhei

      corefonts
      vistafonts

      sarasa-gothic
      nerd-fonts.jetbrains-mono

      font-awesome
      noto-fonts-color-emoji
    ]
  );
  fonts.fontconfig.defaultFonts = {
    serif = [
      "Source Serif 4"
      "Source Han Serif SC"
      "Source Han Serif TC"
      "Source Han Serif HW"
      "Source Han Serif K"
    ];
    sansSerif = [
      "Source Sans 3"
      "Source Han Sans SC"
      "Source Han Sans TC"
      "Source Han Sans HW"
      "Source Han Sans K"
    ];
    monospace = [ "JetBrainsMono Nerd Font Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
  fonts.fontDir.enable = true;
}
