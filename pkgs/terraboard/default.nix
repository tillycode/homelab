{
  source,
  lib,
  stdenv,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  fetchYarnDeps,
  buildGoModule,
  makeWrapper,
}:
let
  inherit (source) pname src;
  version = lib.strings.removePrefix "v" source.version;

  ui = stdenv.mkDerivation {
    pname = "${pname}-ui";
    inherit version src;

    sourceRoot = "${src.name}/static/terraboard-vuejs";

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/static/terraboard-vuejs/yarn.lock";
      hash = source.yarnDepsHash;
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/* $out
      runHook postInstall
    '';

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];
  };
in
buildGoModule {
  inherit pname version src;

  vendorHash = source.vendorHash;

  nativeBuildInputs = [ makeWrapper ];
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # the subPackage ./internal/terraform/configs/configload contains error
  subPackages = [ "." ];

  uiDrv = ui;
  postFixup = ''
    mkdir -p $out/share/terraboard
    ln -s $uiDrv $out/share/terraboard/static
    wrapProgram $out/bin/terraboard --chdir $out/share/terraboard
  '';

  meta = {
    description = "A web dashboard to inspect Terraform States";
    mainProgram = "terraboard";
    homepage = "https://github.com/camptocamp/terraboard";
    license = with lib.licenses; [ asl20 ];
  };
}
