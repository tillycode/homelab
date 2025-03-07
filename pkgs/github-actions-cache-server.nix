{
  stdenv,
  source,
  nodejs,
  pnpm,
  makeWrapper,
  lib,
  srcOnly,
  python3,
}:
let
  nodeSources = srcOnly nodejs;
in
stdenv.mkDerivation (final: {
  inherit (source) pname version src;

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
    makeWrapper
    python3
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit (final) pname version src;
    hash = source.pnpmDepsHash;
  };

  buildPhase = ''
    runHook preBuild

    pushd ./node_modules/.pnpm/better-sqlite3@*/node_modules/better-sqlite3
    npm run build-release --offline --nodedir="${nodeSources}"
    find build -type f -exec remove-references-to -t "${nodeSources}" {} \;
    popd

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/{bin,share/github-actions-cache-server}
    cp -r .output/. $out/share/github-actions-cache-server
    makeWrapper ${nodejs}/bin/node $out/bin/github-actions-cache-server \
      --chdir $out/share/github-actions-cache-server \
      --add-flags $out/share/github-actions-cache-server/server/index.mjs
  '';

  meta = {
    description = "Self-hosted GitHub Actions cache server implementation";
    homepage = "https://github.com/falcondev-oss/github-actions-cache-server/tree/dev";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "github-actions-cache-server";
  };
})
