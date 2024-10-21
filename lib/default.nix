{ lib, inputs }:
let
  data = lib.collect lib.isPath (
    inputs.haumea.lib.load {
      src = ./data;
      loader = with inputs.haumea.lib.matchers; [
        (extension "json" inputs.haumea.lib.loaders.path)
        (extension "toml" inputs.haumea.lib.loaders.path)
      ];
    }
  );
  modules = lib.collect lib.isPath (
    inputs.haumea.lib.load {
      src = ./modules;
      loader = with inputs.haumea.lib.matchers; [
        (extension "nix" inputs.haumea.lib.loaders.path)
      ];
    }
  );
  result = lib.evalModules {
    modules = modules ++ [
      {
        config = lib.pipe data [
          # load the data
          (lib.map (x: if lib.hasSuffix ".json" x then lib.importJSON x else lib.importTOML x))
          # merge all data
          lib.mkMerge
        ];
      }
    ];
  };
  hosts = lib.pipe ../generated/hosts.json [
    lib.importJSON
    (lib.map (x: {
      name = x.hostname;
      value = x;
    }))
    lib.listToAttrs
  ];
in
{
  data = result.config // {
    # for compatibility
    hosts = hosts;
  };
}
