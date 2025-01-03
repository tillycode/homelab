{
  lib,
  python3,
  stdenv,
}:
stdenv.mkDerivation {
  name = "hschip";
  src = ./hschip.py;
  propagatedBuildInputs = [ python3 ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/hschip
  '';
  meta = with lib; {
    description = "A script to change node IP address in the headscale database";
    license = licenses.gpl3;
    mainProgram = "hschip";
    platforms = platforms.all;
  };
}
