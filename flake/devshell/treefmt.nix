{ pkgs, lib, ... }:
{
  treefmt = {
    projectRootFile = ".git/config";

    # global
    settings.global.excludes = lib.mkAfter [
      # unsupported extensions
      "*.{gitignore,tfstate,lock,lock.hcl,tftpl,gitkeep,python-version}"

      # generated files
      "lib/data/**.json"
      "lib/secrets/**.yaml"
      "pkgs/_sources/*"

      # treefmt reports error for symlinks
      ".sops.yaml"

      # legacy generated files
      "generated/*"
      "secrets/*"

      # symlinks
      ".github/actions/with-post-step/post.js"
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
    programs.hclfmt.enable = true;

    # sh
    programs.shfmt.enable = true;
    programs.shellcheck.enable = true;
    settings.formatter.shfmt.includes = [ ".envrc" ];
    settings.formatter.shellcheck.includes = [ ".envrc" ];

    # py
    programs.ruff.check = true;
    programs.ruff.format = true;
  };
}
