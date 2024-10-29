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

  # Transform is applied to each loaded file.
  # If there is a `default` attrset, merge it with other.
  mkDefaultRecursive = lib.mapAttrsRecursive (
    # If 500 between defaultOverridePriority and mkDefault
    k: v: (if lib.isList v then lib.mkBefore else lib.mkOverride 500) v
  );
  transform = lib.mapAttrs (
    category: kv:
    if lib.any (x: x == category) [ "nodes" ] then
      lib.mapAttrs (
        k: v:
        lib.mkMerge [
          (mkDefaultRecursive kv.default or { })
          v
        ]
      ) (lib.removeAttrs kv [ "default" ])
    else
      kv
  );

  evaluated = lib.evalModules {
    modules = modules ++ [
      {
        config = lib.pipe data [
          # load the data
          (lib.map (x: if lib.hasSuffix ".json" x then lib.importJSON x else lib.importTOML x))
          (lib.map transform)
          # merge all data
          lib.mkMerge
        ];
      }
    ];
  };

  # TODO: deprecated configuration. Remove it.
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
  data = evaluated.config // {
    # for compatibility
    hosts = hosts;
  };
}
