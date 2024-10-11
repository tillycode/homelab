{ tailscale, buildGo123Module }:
let
  buildGoModule = buildGo123Module;
in
tailscale.override {
  buildGoModule =
    args:
    buildGoModule (
      args
      // {
        patches = (args.patches or [ ]) ++ [
          ./0001-net-tsaddr-add-TS_CGNAT_RANGE-to-customize-CGNAT-add.patch
        ];
      }
    );
}
