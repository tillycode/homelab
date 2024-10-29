{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  connection = {
    options = {
      ssh_host = mkOption {
        type = types.str;
        description = "The SSH destination";
      };
      bastion_host = mkOption {
        type = types.nullOr types.str;
        description = "The bastion destination, wil be used as ProxyJump";
        default = null;
      };
      ssh_port = mkOption {
        type = types.port;
        description = "The SSH port";
        default = 22;
      };
      ssh_user = mkOption {
        type = types.str;
        description = "The SSH user";
        default = "root";
      };
      bastion_port = mkOption {
        type = types.port;
        description = "The bastion port";
        default = 22;
      };
      bastion_user = mkOption {
        type = types.str;
        description = "The bastion user";
        default = "root";
      };
    };
  };

  profiles = types.listOf (types.either types.str (types.attrsOf types.anything));
  node =
    {
      config,
      name,
      suites,
      ...
    }:
    {
      options = {
        # connections = mkOption {
        #   type = types.attrsOf (types.submodule connection);
        #   description = "The connections to the node";
        #   default = { };
        # };
        system = mkOption {
          type = types.str;
        };

        profiles = mkOption {
          type = profiles;
          description = ''
            The profiles to apply to the node

            Each profile is a dot-separated path under `nixos/profiles` or
            a object representing node configurations.
          '';
          default = [ ];
        };

        suites = mkOption {
          type = types.listOf types.str;
          description = ''
            The suites to apply to the node
          '';
          default = [ ];
        };
      };

      config = {
        ssh_host = lib.mkDefault name;

        profiles = (lib.concatMap (suite: suites.${suite}.profiles) config.suites) ++ [
          {
            networking.hostName = "${name}";
            nixpkgs = {
              system = config.system;
            };

            system.stateVersion = "24.11";
          }
        ];
      };
    };

  suite = {
    options = {
      profiles = mkOption {
        type = profiles;
        description = ''
          The profiles the suite is composed of
        '';
        default = [ ];
      };

    };
  };
in
{
  options.nodes = mkOption {
    description = "Nodes";
    type = types.attrsOf (
      types.submoduleWith {
        modules = [
          connection
          node
        ];
        specialArgs = {
          suites = config.suites;
        };
      }
    );
  };

  options.suites = mkOption {
    description = "Collection of profiles";
    type = types.attrsOf (types.submodule suite);
    default = { };
  };
}
