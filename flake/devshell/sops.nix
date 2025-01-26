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
    hgh0 = "age1f8jdv6xagt92t44qhnnflkazfe03rry0w6da2eqdv3dwkwppwatqxkgj9w";
    hgh1 = "age1ydjlaersukg2jms5hrjz7z2ja0htlln40uexcmcg2yxzlny8s39qc88wya";
    hgh2 = "age1q93v8zc62mczmz30wy04n8erlfhhhjc3k7a3vspccjqpvehxadyqgrzrue";
    sha0 = "age1a46mp4kgk3jdvt520ng9ta45zv0ns0xts9xvjza04t3mpmrfjdqs52s6vh";
    sin0 = "age1pf03m77v3wpz4qtzc6nrlkvj4pdxffpwtg789g8zjq753hj2ug8qnsnttt";
    desktop = "age1v6lnkm7prm0dpmcdpvn44v50rpfkzsed5uv3znxt4grsd5y6sv5qjru9qq";
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
