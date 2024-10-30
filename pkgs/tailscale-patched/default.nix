{ tailscale, buildGo123Module }:
tailscale.override {
  buildGo123Module =
    args:
    buildGo123Module (
      args
      // {
        patches = (args.patches or [ ]) ++ [
          ./0001-net-tsaddr-add-TS_CGNAT_RANGE-to-customize-CGNAT-add.patch
        ];
      }
    );
}
