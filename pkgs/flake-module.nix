{
  perSystem =
    { pkgs, config, ... }:
    let
      sources = pkgs.callPackages (import ./_sources/generated.nix) { };
    in
    {
      overlayAttrs = {
        inherit (config.packages)
          tailscale-patched
          headscale-ui
          hschip
          terraboard
          sing-box_1_12
          github-actions-cache-server
          github-runner-patched
          attic-client_patched
          ;
      };
      packages = {
        tailscale-patched = pkgs.callPackage (import ./tailscale-patched) { };
        headscale-ui = pkgs.callPackage (import ./headscale-ui) {
          source = sources.headscale-ui;
        };
        hschip = pkgs.callPackage (import ./hschip) { };
        terraboard = pkgs.callPackage (import ./terraboard) {
          source = sources.terraboard;
        };
        sing-box_1_12 = pkgs.sing-box.overrideAttrs (oldAttrs: rec {
          inherit (sources.sing-box)
            pname
            version
            src
            vendorHash
            ;
          tags = (pkgs.lib.filter (x: x != "with_ech" && x != "with_reality_server") oldAttrs.tags) ++ [
            "with_tailscale"
          ];
          ldflags = "-X=github.com/sagernet/sing-box/constant.Version=${version}";
        });
        github-actions-cache-server = pkgs.callPackage (import ./github-actions-cache-server.nix) {
          source = sources.github-actions-cache-server;
        };
        github-runner-patched = pkgs.callPackage (import ./github-runner-patched) { };
        attic-client_patched = pkgs.attic-client.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [ ./attic-client-graceful-shutdown.patch ];
        });
      };
    };
}
