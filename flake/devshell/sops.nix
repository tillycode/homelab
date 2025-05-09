{
  lib,
  ...
}:
let
  source-keys = {
    # ziping_sun
    pgp = [
      "8CC5C91F72DB57DA20BD848C6523836CF4992251"
    ];
    kms = [
      # github-actions
      { arn = "arn:aws:kms:ap-southeast-1:137927498482:alias/sops-key"; }
    ];
  };
  source-paths = [
    "^secrets/sources/.*\\.(yaml|json)$"
    "^.data/tfplans.tar.gz$"
  ];
  node-keys = {
    hgh0 = "age1q93v8zc62mczmz30wy04n8erlfhhhjc3k7a3vspccjqpvehxadyqgrzrue";
    hkg0 = "age1gp0jvxqvjpz9gc6ewaggetxsp0phwyrrvagw57j9tzea507g2y3qpqwwa4";
    sha0 = "age1a46mp4kgk3jdvt520ng9ta45zv0ns0xts9xvjza04t3mpmrfjdqs52s6vh";
    desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq";
    laptop = "age1kgcxdnuy9fxtcf6fp7camk6tqm0fset0jvvh9760rqmrkmx99v0q2c7w8e";
    r2s = "age1qfp5p3h97anl95lal6c23zp38lp03ltdd7jnkmw6qtgu89e59vsq9t8z83";
  };
  sops_source_creation_rule = lib.map (path_regex: {
    path_regex = path_regex;
    key_groups = [ source-keys ];
  }) source-paths;
  sops_host_creation_rules = lib.pipe node-keys [
    lib.attrsToList
    (lib.map (
      { name, value }:
      {
        path_regex = "^secrets/nodes/${name}\\.yaml$";
        key_groups = [ { age = [ value ]; } ];
      }
    ))
  ];
in
{
  nixago.configs = [
    {
      data = {
        creation_rules = sops_source_creation_rule ++ sops_host_creation_rules;
      };
      format = "yaml";
      output = ".sops.yaml";
    }
  ];
}
