{
  hardware.bluetooth.enable = true;
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/bluetooth";
      mode = "0700";
    }
  ];
}
