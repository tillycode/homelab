{
  lib,
  headscale,
  sources,
  buildGoModule,
}:
let
  source = sources.headscale;
in
headscale.override {
  buildGoModule =
    args:
    buildGoModule (
      args
      // rec {
        inherit (source) pname src;
        version = lib.strings.removePrefix "v" source.version;

        # no longer needs the backported patch juanfont/headscale#1697
        patches = [ ];

        ldflags = [
          "-s"
          "-w"
          "-X github.com/juanfont/headscale/cmd/headscale/cli.Version=v${version}"
        ];

        vendorHash = "sha256-EorT2AVwA3usly/LcNor6r5UIhLCdj3L4O4ilgTIC2o=";
      }
    );
}
