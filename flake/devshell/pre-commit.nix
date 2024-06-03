{ ... }:
{
  perSystem =
    { ... }:
    {
      pre-commit.settings.hooks = {
        # actionlint.enable = true;
        check-json.enable = true;
        check-added-large-files.enable = true;
        check-yaml.enable = true;
        # checkmake.enable = true;
        markdownlint.enable = true;
        treefmt.enable = true;
      };
    };
}
