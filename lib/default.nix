{ lib }:
{
  data.hosts = lib.pipe ../generated/hosts.json [
    lib.importJSON
    (lib.map (x: {
      name = x.hostname;
      value = x;
    }))
    lib.listToAttrs
  ];
}
