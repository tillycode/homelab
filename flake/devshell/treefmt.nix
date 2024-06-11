{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";
        programs = {
          nixfmt-rfc-style.enable = true;
          prettier.enable = true;
          taplo.enable = true;
          terraform.enable = true;
          terraform.package = pkgs.opentofu;
        };

        settings.formatter.terragrunt = {
          command = pkgs.bash;
          options = [
            "-euc"
            ''
              for f in "$@"; do
                ${pkgs.terragrunt}/bin/terragrunt hclfmt --terragrunt-hclfmt-file "$f"
              done
            ''
          ];
          includes = [ "terragrunt.hcl" ];
        };
      };
    };
}
