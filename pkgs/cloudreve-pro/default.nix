{
  stdenvNoCC,
  requireFile,
  lib,
}:
let
  version = "4.5.1";
  hash = "sha256-U+hc1ISK4ff4wNZeOEOEgu+ZjygFNYtTa69fJcLA+HM=";
in
stdenvNoCC.mkDerivation {
  pname = "cloudreve-pro";
  inherit version;
  src = requireFile {
    name = "cloudreve_${version}_linux_amd64.tar.gz";
    url = "https://cloudreve.org/manage";
    hash = hash;
  };
  sourceRoot = ".";
  installPhase = ''
    install -m 0755 -D cloudreve $out/bin/cloudreve
  '';
  meta = with lib; {
    description = "Self-hosted file management and sharing system, supports multiple storage providers";
    homepage = "https://cloudreve.org/";
    license = licenses.unfree;
    mainProgram = "cloudreve";
  };
}
