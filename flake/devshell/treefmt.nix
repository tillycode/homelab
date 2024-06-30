{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = ".git/config";

        # FIXME: GitHub workflows are not formatted (numtide/treefmt#273)
        # treefmt v0.6.1 doesn't scan hidden files, so directory like `.github`
        # will be ignored. They added `--hidden` flag in the main branch, but
        # it's not released yet.
        # json, yaml, markdown
        programs.prettier.enable = true;
        settings.formatter.prettier.excludes = [
          "terraform/bootstrap/output.json"
          "secrets/*"
          "pkgs/_sources/*"
        ];

        # nix
        programs.nixfmt-rfc-style.enable = true;
        settings.formatter.nixfmt-rfc-style.excludes = [ "pkgs/_sources/*" ];

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
      };
    };
}
