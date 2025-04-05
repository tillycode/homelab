{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ens5" ];
    externalInterface = "ens5";
  };
}
