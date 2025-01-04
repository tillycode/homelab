{
  networking.wireless.iwd.enable = true;
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/iwd";
      mode = "0700";
    }
  ];
}
