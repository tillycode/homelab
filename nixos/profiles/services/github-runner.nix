{ config, lib, ... }:
let
  num = 5;

  user = "github-runner";
  group = "github-runner";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.github-runners = lib.pipe num [
    (lib.range 1)
    (lib.map (n: if n < 10 then "0${toString n}" else toString n))
    (lib.map (n: {
      name = "${n}";
      value = {
        enable = true;
        name = "${config.networking.hostName}-${n}";
        url = "https://github.com/tillycode";
        tokenFile = config.sops.secrets."github-runner/token".path;
        replace = true;
        ephemeral = true;
        user = user;
        group = group;
        noDefaultLabels = true;
        extraLabels = [
          "nixos-${config.nixpkgs.system}"
        ];
      };
    }))
    lib.listToAttrs
  ];

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."github-runner/token" = { };

  ## ---------------------------------------------------------------------------
  ## USERS
  ## ---------------------------------------------------------------------------
  users.users.${user} = {
    isSystemUser = true;
    group = group;
    description = "GitHub Runner";
  };
  users.groups.${group} = { };
  nix.settings.trusted-users = [ user ];
}
