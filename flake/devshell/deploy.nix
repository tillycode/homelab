{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # TODO(low): refactor devshell
      devshells.default.commands = [
        {
          category = "deployment";
          name = "deploy";
          package = pkgs.deploy-rs.deploy-rs;
        }
      ];
    };
}
