# https://github.com/linyinfeng/nur-packages/blob/master/flake-modules/nixago.nix
# https://github.com/nix-community/nixago/blob/master/modules/request.nix
{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkPerSystemOption;

  nixagoConfig =
    { system }:
    { ... }:
    {
      options = {
        data = mkOption {
          type = types.anything;
          description = ''
            Data of the configuration file.
          '';
        };
        output = mkOption {
          type = types.str;
          description = ''
            Name of output file.
          '';
        };
        format = mkOption {
          type = types.str;
          description = ''
            Format of the configuration file.
          '';
        };
        engine = mkOption {
          type = types.unspecified;
          default = inputs.nixago.engines.${system}.nix { };
          defaultText = lib.literalExpression "inputs.nixago.engines.\${system}.nix { }";
          description = ''
            Engine used to generate configuration file.
          '';
        };
      };
    };
in
{

  options.perSystem = mkPerSystemOption (
    { config, system, ... }:
    {
      options = {
        nixago = {
          configs = mkOption {
            type = types.listOf (
              types.submodule (nixagoConfig {
                inherit system;
              })
            );
            default = [ ];
            description = ''
              List of nixago configurations.
            '';
          };
          shellHook = mkOption {
            type = types.str;
            default =
              if (lib.length config.nixago.configs) != 0 then
                (inputs.nixago.lib.${system}.makeAll config.nixago.configs).shellHook
              else
                "";
            defaultText = lib.literalExpression ''
              if (lib.length config.nixago.configs) != 0 then
                (inputs.nixago.lib.''${system}.makeAll config.nixago.configs).shellHook
              else
                ""'';
            readOnly = true;
            description = ''
              Shell hook string of nixago.
            '';
          };
        };
      };
    }
  );
}
