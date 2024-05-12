{ source, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "kexec-installer-nixos-unstable-noninteractive";
  inherit (source) version src;

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out
    cp $src $out/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
  '';
}
