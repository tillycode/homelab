# based on https://github.com/daeuniverse/flake.nix/blob/main/daed/module.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    literalExpression
    types
    mkPackageOption
    ;

  cfg = config.services.daed;
  genAssetsDrv =
    paths:
    pkgs.symlinkJoin {
      name = "dae-assets";
      inherit paths;
    };
in
{
  # disables Nixpkgs daed module to avoid conflicts
  disabledModules = [ "services/networking/daed.nix" ];

  options = {
    services.daed = {
      enable = mkEnableOption "A modern dashboard for dae";

      package = mkPackageOption pkgs "daed" { };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/daed";
        description = "The daed work directory.";
      };

      listen = mkOption {
        type = types.str;
        default = "127.0.0.1:2023";
        description = "The daed listen address.";
      };

      assets = mkOption {
        type = with types; (listOf path);
        default = with pkgs; [
          v2ray-geoip
          v2ray-domain-list-community
        ];
        defaultText = literalExpression "with pkgs; [ v2ray-geoip v2ray-domain-list-community ]";
        description = "Assets required to run dae.";
      };

      assetsPath = mkOption {
        type = types.str;
        default = "${genAssetsDrv cfg.assets}/share/v2ray";
        defaultText = literalExpression ''
          "$\{(symlinkJoin {
              name = "dae-assets";
              paths = assets;
          })}/share/v2ray"
        '';
        description = ''
          The path which contains geolocation database.
          This option will override `assets`.
        '';
      };
      openFirewall = mkOption {
        type = types.submodule {
          options = {
            enable = mkEnableOption "enable";
            port = mkOption {
              type = types.int;
              description = ''
                Port to be opened. Consist with field `tproxy_port` in config file.
              '';
            };
          };
        };
        default = {
          enable = true;
          port = 12345;
        };
        defaultText = literalExpression ''
          {
            enable = true;
            port = 12345;
          }
        '';
        description = "Open the firewall port.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    systemd.packages = [ cfg.package ];

    networking = lib.mkIf cfg.openFirewall.enable {
      firewall =
        let
          portToOpen = cfg.openFirewall.port;
        in
        {
          allowedTCPPorts = [ portToOpen ];
          allowedUDPPorts = [ portToOpen ];
        };
    };

    systemd.services.daed =
      let
        daedBin = lib.getExe cfg.package;
      in
      {
        wantedBy = [ "multi-user.target" ];
        environment.DAE_LOCATION_ASSET = cfg.assetsPath;
        serviceConfig = {
          ExecStart = [
            ""
            "${daedBin} run -c ${cfg.configDir} -l ${cfg.listen}"
          ];
          RuntimeDirectory = "daed";
        };
      };
  };
}
