{
  source,
  stdenv,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  buildGoModule,
  zip,
  lib,
}:
let
  inherit (source) pname version src;
  frontend = stdenv.mkDerivation {
    pname = "${pname}-frontend";
    inherit version src;
    sourceRoot = "${src.name}/assets";

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/assets/yarn.lock";
      fixupPhase = ''
        sed -i 's/github://' "$out/yarn.lock"
      '';
      hash = source.yarnDepsHash;
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];

    preBuild = ''
      yarn version --new-version ${version} --no-git-tag-version
    '';
    patchPhase = ''
      sed -i 's/github://' yarn.lock
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r build/* $out
      runHook postInstall
    '';
  };
in
buildGoModule {
  inherit pname version src;
  vendorHash = source.vendorHash;
  nativeBuildInputs = [
    zip
  ];
  preBuild = ''
    rm -rf assets/build
    mkdir -p assets/build
    cp -r ${frontend}/* assets/build
    zip -r - assets/build >application/statics/assets.zip
  '';

  ldflags = [
    "-s"
    "-w"
    "-X"
    "github.com/cloudreve/Cloudreve/v4/application/constants.BackendVersion=${version}"
    "-X"
    "github.com/cloudreve/Cloudreve/v4/application/constants.LastCommit=${src.rev}"
  ];
  doCheck = false;
  postInstall = ''
    mv $out/bin/Cloudreve $out/bin/cloudreve
  '';

  meta = {
    description = "Self-hosted file management and sharing system, supports multiple storage providers";
    mainProgram = "cloudreve";
    homepage = "https://cloudreve.org/";
    license = with lib.licenses; [ gpl3 ];
  };
}
