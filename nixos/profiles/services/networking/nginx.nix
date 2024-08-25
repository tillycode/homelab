{
  security.acme = {
    acceptTerms = true;
    defaults.email = "me@szp.io";
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedZstdSettings = true;
    recommendedBrotliSettings = true;
  };
}
