{ ... }:
{
  perSystem =
    { ... }:
    {
      pre-commit.settings.hooks = {
        check-json.enable = true;
        check-added-large-files.enable = true;
        check-yaml.enable = true;
        treefmt.enable = true;
      };
    };
}
