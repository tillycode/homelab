{ tailscale }:
tailscale.overrideAttrs (oldAtts: {
  patches = (oldAtts.patches or [ ]) ++ [
    ./0001-net-tsaddr-add-TS_CGNAT_RANGE-to-customize-CGNAT-add.patch
  ];
  doCheck = false;
})
