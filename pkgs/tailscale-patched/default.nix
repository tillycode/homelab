{ tailscale }:
tailscale.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches ++ [ ./0001-net-tsaddr-add-TS_CGNAT_RANGE-to-customize-CGNAT-add.patch ];
})
