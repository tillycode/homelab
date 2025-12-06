{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    let
      sources = pkgs.callPackages (import ./_sources/generated.nix) { };
    in
    {
      overlayAttrs = {
        inherit (config.packages)
          tailscale-patched
          headscale-ui
          hschip
          sing-box_1_12
          github-actions-cache-server
          github-runner-patched
          attic-client_patched
          cloudreve
          cloudreve-pro
          rke2_1_32
          rke2_1_33
          rke2_1_34
          zteonu
          ;
      }
      // (
        if system == "aarch64-linux" then
          {
            inherit (config.packages) uboot-nanopi-r2s;
          }
        else
          { }
      );
      packages = {
        tailscale-patched = pkgs.callPackage (import ./tailscale-patched) { };
        headscale-ui = pkgs.callPackage (import ./headscale-ui) {
          source = sources.headscale-ui;
        };
        hschip = pkgs.callPackage (import ./hschip) { };
        sing-box_1_12 = pkgs.sing-box.overrideAttrs (oldAttrs: rec {
          inherit (sources.sing-box)
            pname
            version
            src
            vendorHash
            ;
          ldflags = "-X=github.com/sagernet/sing-box/constant.Version=${version}";
        });
        github-actions-cache-server = pkgs.callPackage (import ./github-actions-cache-server.nix) {
          source = sources.github-actions-cache-server;
        };
        github-runner-patched = pkgs.callPackage (import ./github-runner-patched) { };
        attic-client_patched = pkgs.attic-client.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [ ./attic-client-graceful-shutdown.patch ];
        });
        cloudreve = pkgs.callPackage (import ./cloudreve) {
          source = sources.cloudreve;
        };
        cloudreve-pro = pkgs.callPackage (import ./cloudreve-pro) { };
        inherit
          (pkgs.callPackage (import ./rke2) {
            inherit (inputs) nixpkgs;
          })
          rke2_1_32
          rke2_1_33
          rke2_1_34
          ;
        zteonu = pkgs.callPackage (import ./zteonu) {
          source = sources.zteonu;
        };
      }
      // (
        if system == "aarch64-linux" then
          {
            uboot-nanopi-r2s = pkgs.callPackage (import ./uboot-nanopi-r2s) { };
          }
        else
          { }
      );
    };
}
