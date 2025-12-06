{
  source,
  buildGoModule,
  lib,
}:
buildGoModule {
  inherit (source) pname version src;
  vendorHash = source.vendorHash;
  meta = {
    description = "A tool that can open ZTE onu device factory mode";
    mainProgram = "zteOnu";
    homepage = "https://github.com/Septrum101/zteOnu";
    license = with lib.licenses; [ agpl3Only ];
  };
}
