{ config, ... }:
let
  domain = config.domains.grafana;
  acmeDomain = config.domains.acme;
  port = config.ports.grafana;
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.grafana = {
    enable = true;
    settings = {
      server = {
        protocol = "http";
        http_addr = "::1";
        http_port = port;
        domain = domain;
        root_url = "https://${domain}/";
      };
      database = {
        type = "sqlite3";
      };
      security = {
        disable_initial_admin_creation = true;
        secret_key = "$__file{${config.sops.secrets."grafana/secretKey".path}}";
      };
      auth = {
        disable_login_form = true;
        signout_redirect_url = "https://login.szp15.com/oidc/v1/end_session";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "SSO (login.szp15.com)";
        auth_url = "https://login.szp15.com/oauth/v2/authorize";
        token_url = "https://login.szp15.com/oauth/v2/token";
        api_url = "https://login.szp15.com/oidc/v1/userinfo";
        client_id = "$__file{${config.sops.secrets."grafana/clientId".path}}";
        client_secret = "$__file{${config.sops.secrets."grafana/clientSecret".path}}";
        scopes = "openid email profile";
        use_kce = true;
        email_attribute_name = "email";
        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        role_attribute_path = "contains(groups[*], 'admin') && 'GrafanaAdmin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
        allow_assign_grafana_admin = true;
      };
      analytics = {
        reporting_enabled = false;
      };
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."grafana/clientId" = {
    owner = "grafana";
  };
  sops.secrets."grafana/clientSecret" = {
    owner = "grafana";
  };
  sops.secrets."grafana/secretKey" = {
    owner = "grafana";
  };

  ## ---------------------------------------------------------------------------
  ## INGRESS
  ## ---------------------------------------------------------------------------
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };

    extraConfig = ''
      allow 100.71.0.0/16;
      allow fd7a:115c:a1e0:7::/64;
      allow 10.75.0.0/16;
      allow fd42:e16c:cbc4::/48;
      deny all;
    '';
  };
  security.acme.certs."${domain}" = {
    server = "https://${acmeDomain}/acme/acme/directory";
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "${config.services.grafana.dataDir}";
      mode = "0700";
      user = "grafana";
      group = "grafana";
    }
  ];
}
