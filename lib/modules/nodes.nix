{ lib, ... }:
with lib;
{
  options.nodes = mkOption {
    type =
      with types;
      lazyAttrsOf (submodule {
        options = {
          ssh_host = mkOption {
            type = nullOr str;
            description = "The SSH host of the node";
            default = null;
          };
          bastion_host = mkOption {
            type = nullOr str;
            description = "The bastion host of the node";
            default = null;
          };
        };
      });
  };
}
