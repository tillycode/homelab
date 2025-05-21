{
  imports = [
    ./_rke2-common.nix
  ];

  services.rke2 = {
    role = "server";
  };
}
