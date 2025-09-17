{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      pantum-driver
      cups-filters
      cups-browsed
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
