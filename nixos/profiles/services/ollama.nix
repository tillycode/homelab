{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/ollama";
      mode = "0700";
    }
  ];
}
