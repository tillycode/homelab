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
        markdownlint.settings.configuration = {
          MD013 = {
            tables = false;
          };
        };
        treefmt.enable = true;
      };
    };
}
