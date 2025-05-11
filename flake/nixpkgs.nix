{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlay
          inputs.nix-minecraft.overlay
          self.overlays.default
          (final: prev: {
            fetchLocalPackwizModpack =
              { root, ... }@args:
              (pkgs.fetchPackwizModpack ({ url = ""; } // args)).overrideAttrs (old: {
                buildInputs = with pkgs; [
                  jre_headless
                  jq
                  moreutils
                ];
                buildPhase = ''
                  java -jar "$packwizInstallerBootstrap" \
                    --bootstrap-main-jar "$packwizInstaller" \
                    --bootstrap-no-update \
                    --no-gui \
                    --side "server" \
                    "${root}/pack.toml"
                '';
                passthru = old.passthru // {
                  manifest = final.lib.importTOML "${root}/pack.toml";
                };
              });
          })
        ];
        config = {
          allowUnfree = true;
        };
      };

      legacyPackages = pkgs;
    };
}
