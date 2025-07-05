{
  lib,
  config,
  pkgs,
  ...
}:
let
  package = pkgs.terraboard;
  domain = config.domains.terraboard;

  endSessionEndpoint = "https://${config.domains.zitadel}/oidc/v1/end_session";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  systemd.services.terraboard = {
    enable = true;
    description = "A web dashboard to inspect Terraform States";
    wantedBy = [ "multi-user.target" ];

    environment = {
      DB_HOST = "/run/postgresql";
      DB_USER = "terraboard";
      DB_NAME = "terraboard";
      # DB_SSLMODE = "disable";

      AWS_FORCE_PATH_STYLE = "true";
      TERRABOARD_NO_VERSIONING = "true";

      TERRABOARD_PORT = toString config.ports.terraboard;
      TERRABOARD_SWAGGER_PORT = toString config.ports.terraboard-swagger;
    };

    serviceConfig = {
      ExecStart = lib.getExe package;
      EnvironmentFile = [
        config.sops.templates."terraboard/config.env".path
      ];
      User = "terraboard";
      Group = "terraboard";
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."terraboard/awsRegion" = { };
  sops.secrets."terraboard/awsAccessKeyId" = { };
  sops.secrets."terraboard/awsSecretAccessKey" = { };
  sops.secrets."terraboard/awsBucket" = { };
  sops.secrets."terraboard/awsDynamodbTable" = { };
  sops.templates."terraboard/config.env" = {
    content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."terraboard/awsAccessKeyId"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."terraboard/awsSecretAccessKey"}
      AWS_REGION=${config.sops.placeholder."terraboard/awsRegion"}
      AWS_BUCKET=${config.sops.placeholder."terraboard/awsBucket"}
      AWS_DYNAMODB_TABLE=${config.sops.placeholder."terraboard/awsDynamodbTable"}
    '';

  };

  ## ---------------------------------------------------------------------------
  ## DATABASE
  ## ---------------------------------------------------------------------------
  services.postgresql.ensureDatabases = [ "terraboard" ];
  services.postgresql.ensureUsers = [
    {
      name = "terraboard";
      ensureDBOwnership = true;
    }
  ];
  assertions = [
    {
      assertion = config.services.postgresql.enable;
      message = "PostgreSQL service must be enabled for Terraboard";
    }
  ];

  ## ---------------------------------------------------------------------------
  ## USERS
  ## ---------------------------------------------------------------------------
  users.users.terraboard = {
    isSystemUser = true;
    group = "terraboard";
    description = "Terraboard";
  };
  users.groups.terraboard = { };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.terraboard}";
      extraConfig = ''
        proxy_set_header X-Forwarded-User $preferred_username;
        proxy_set_header X-Forwarded-Email $email;
      '';
    };
    locations."/oauth2/sign_in" = {
      return = "307 https://${config.domains.oauth2-proxy}/oauth2/sign_out?rd=${lib.escapeURL endSessionEndpoint}";
      extraConfig = ''
        auth_request off;
      '';
    };
    extraConfig = ''
      auth_request_set $preferred_username $upstream_http_x_auth_request_preferred_username;
      allow 100.120.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs.${domain} = {
    server = "https://${config.domains.acme}/acme/acme/directory";
  };
  services.oauth2-proxy.nginx.virtualHosts.${domain} = { };
}
