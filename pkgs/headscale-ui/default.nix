{ source, buildNpmPackage }:
buildNpmPackage {
  inherit (source) pname version src;
  npmDepsHash = source.npmDepsHash;

  installPhase = ''
    echo "executing installPhase"
    mkdir -p $out
    cp -r build/* $out
  '';
}
