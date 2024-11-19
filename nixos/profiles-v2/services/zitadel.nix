{
  config,
  lib,
  pkgs,
  ...
}:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.zitadel = {
    enable = true;
    masterKeyFile = config.sops.secrets."zitadel/masterKey".path;
    # see https://zitadel.com/docs/self-hosting/manage/configure
    settings = {
      Port = config.ports.zitadel;
      # see https://zitadel.com/docs/self-hosting/manage/custom-domain
      ExternalDomain = config.domains.zitadel;
      ExternalPort = 443;
      ExternalSecure = true;
      # TLS termination
      TLS.Enabled = false;
      # Database configuration
      Database.postgres = {
        Host = "/run/postgresql";
        # Zitadel will report error if port is not set
        Port = 5432;
        Database = "zitadel";
        User.Username = "zitadel";
      };
      DefaultInstance = {
        SMTPConfiguration = {
          SMTP = {
            Host = "smtp.feishu.cn:465";
            User = "zitadel@szp.io";
          };
          TLS = true;
          From = "zitadel@szp.io";
          FromName = "Zitadel";
          ReplyToAddress = "me@szp.io";
        };
        LoginPolicy = {
          AllowRegister = false;
          AllowDomainDiscovery = false;
          IgnoreUnknownUsernames = true;
        };
        Restrictions = {
          DisallowPublicOrgRegistration = true;
        };
      };
    };
    extraSettingsPaths = [
      config.sops.templates."zitadel-config.yaml".path
    ];
    steps = {
      FirstInstance = {
        Org.Human = {
          UserName = "ziping-sun";
          FirstName = "Ziping";
          LastName = "Sun";
          Email.Address = "me@szp.io";
        };
      };
    };
    extraStepsPaths = [
      config.sops.templates."zitadel-steps.yaml".path
    ];
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."zitadel/masterKey" = {
    owner = "zitadel";
    group = "zitadel";
    restartUnits = [ "zitadel.service" ];
  };
  sops.secrets."zitadel/smtpPassword" = { };
  sops.templates."zitadel-config.yaml" = {
    content = ''
      DefaultInstance:
        SMTPConfiguration:
          SMTP:
            Password: ${config.sops.placeholder."zitadel/smtpPassword"}
    '';
    owner = "zitadel";
    group = "zitadel";
    restartUnits = [ "zitadel.service" ];
  };
  sops.secrets."zitadel/initialAdminPassword" = { };
  sops.templates."zitadel-steps.yaml" = {
    content = ''
      FirstInstance:
        Org:
          Human:
            Password: ${config.sops.placeholder."zitadel/initialAdminPassword"}
    '';
    owner = "zitadel";
    group = "zitadel";
    restartUnits = [ "zitadel.service" ];
  };

  ## ---------------------------------------------------------------------------
  ## DATABASE
  ## ---------------------------------------------------------------------------
  services.postgresql.ensureDatabases = [ "zitadel" ];
  services.postgresql.ensureUsers = [
    {
      name = "zitadel";
      ensureDBOwnership = true;
    }
  ];
  assertions = [
    {
      assertion = config.services.postgresql.enable;
      message = "PostgreSQL service must be enabled for Zitadel";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${config.domains.zitadel} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      extraConfig = ''
        grpc_pass grpc://[::1]:${toString config.ports.zitadel};
        grpc_set_header Host $host;
      '';
    };
  };
  warnings = lib.optionals (!config.services.nginx.enable) [
    "Nginx service is not enabled, Zitadel will not be accessible"
  ];

  ## ---------------------------------------------------------------------------
  ## HACKS
  ## ---------------------------------------------------------------------------
  # The original service provided by NixOS runs `zitadel start-from-init`.
  # This command consists of three steps: `init`, `step`, and `start`.
  # During the `init` step, Zitadel connects to the database with
  # admin credentials to create the database and user.
  # It then connects to the database with normal user credentials
  # to migrate the database (`init zitadel`).
  #
  # In our case, we don't want to give Zitadel admin credentials.
  # Therefore, we only need to run `init zitadel`, followed by `start-from-setup`.
  systemd.services.zitadel =
    let
      cfg = config.services.zitadel;

      settingsFormat = pkgs.formats.yaml { };

      configFile = settingsFormat.generate "config.yaml" cfg.settings;
      stepsFile = settingsFormat.generate "steps.yaml" cfg.steps;

      initArgs = lib.cli.toGNUCommandLineShell { } {
        config = cfg.extraSettingsPaths ++ [ configFile ];
      };
      args = lib.cli.toGNUCommandLineShell { } {
        config = cfg.extraSettingsPaths ++ [ configFile ];
        steps = cfg.extraStepsPaths ++ [ stepsFile ];
        masterkeyFile = cfg.masterKeyFile;
        inherit (cfg) tlsMode;
      };
    in
    {
      preStart = ''
        zitadel init zitadel ${initArgs}
      '';
      script = lib.mkForce ''
        exec zitadel start-from-setup ${args}
      '';
      wants = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
}
