{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, lib, ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";

        # global
        settings.global.excludes = lib.mkAfter [
          # unsupported extensions
          "*.gitignore"

          # state file or lock file managed by tools
          "*.{tfstate,lock,lock.hcl}"

          # generated files
          "generated/*"
          "secrets/*"
          "pkgs/_sources/*"
        ];

        # json, yaml, markdown
        programs.prettier.enable = true;

        # nix
        programs.nixfmt.enable = true;
        settings.formatter.nixfmt.excludes = [ "pkgs/_sources/*" ];

        # toml
        programs.taplo.enable = true;

        # tf
        programs.terraform.enable = true;
        programs.terraform.package = pkgs.opentofu;

        # hcl
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
          includes = [ "*.hcl" ];
        };

        # sh
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shfmt.includes = [ ".envrc" ];
        settings.formatter.shellcheck.includes = [ ".envrc" ];
      };
    };
}
