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
    hkg0 = "age1luasnwh2kjtck7c25msmhy2k4dxw966609kt3r3sfj3yxlwgrdlqcgmmxn";
    sha0 = "age1cfyre76ucj4a7dw34w2ura5yc9wl9u2a6uj5gdyc82fyjm6mrdeqwn24l6";
    desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq";
    laptop = "age1kgcxdnuy9fxtcf6fp7camk6tqm0fset0jvvh9760rqmrkmx99v0q2c7w8e";
    r2s = "age1qfp5p3h97anl95lal6c23zp38lp03ltdd7jnkmw6qtgu89e59vsq9t8z83";
    router = "age1a2zxjefhj2dprsxjvdsaw8swlsxqvhznwql4eva9v7amw94glevs8p4qlz";
    hasee01 = "age1zkg99svpjg99wnzp9qatvt6wufmcnwd6xlg8zj786sad8nv64ylsrkp0u5";
    hasee02 = "age1dn753h8kvk48ncvvhqe954julnp5azecscpzpedr6nn0g9lydaws8s2dmd";
    hasee03 = "age10dc0rdkjx7px07ruws2k68sm7apuuw72qvqc9n7eec7haxyx95gse36qc5";
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
