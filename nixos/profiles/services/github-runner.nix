{
  config,
  lib,
  pkgs,
  ...
}:
let
  num = 5;

  user = "github-runner";
  group = "github-runner";

  mkRunners =
    f:
    lib.pipe num [
      (lib.range 1)
      (lib.map (n: if n < 10 then "0${toString n}" else toString n))
      (lib.map f)
      lib.listToAttrs
    ];

  package = pkgs.github-runner-patched;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.github-runners = mkRunners (
    n:
    lib.nameValuePair n {
      enable = true;
      package = package;
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
        config.networking.hostName
      ];
      extraEnvironment = {
        ACTIONS_RESULTS_URL = "https://${config.domains.gha-cache-server}/";
        ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE = "/var/cache/github-runner/actions";
        ACTIONS_RUNNER_ACTION_ARCHIVE_EXTERNAL_CACHING_ENABLED = "true";
      };
      serviceOverrides = {
        Restart = lib.mkForce "always";
      };
    }
  );

  systemd.services = mkRunners (
    n:
    lib.nameValuePair "github-runner-${n}" {
      after = [ "sing-box.service" ];
      serviceConfig = {
        CacheDirectory = "github-runner/actions";
      };
    }
  );

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

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/cache/github-runner";
      inherit user group;
      mode = "0700";
    }
  ];

}
