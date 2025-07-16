{
  rke2Version = "1.32.6+rke2r1";
  rke2Commit = "54f49419945b6f2956d03973c1e8f287f47905b1";
  rke2TarballHash = "sha256-PGR4vSTNhKg0wPtAuFcd17eQ9WiKEU2u/4U2bK5y7GM=";
  rke2VendorHash = "sha256-iWj9SemqEOfGILx3oRCrxYLjCOV0NW8OcTU0djvWW70=";
  k8sImageTag = "v1.32.6-rke2r1-build20250618";
  etcdVersion = "v3.5.21-k3s1-build20250612";
  pauseVersion = "3.6";
  ccmVersion = "v1.32.5-rc1.0.20250516182639-8e8f2a4726fd-build20250612";
  dockerizedVersion = "v1.32.6-rke2r1";
  imagesVersions = with builtins; fromJSON (readFile ./images-versions.json);
}
