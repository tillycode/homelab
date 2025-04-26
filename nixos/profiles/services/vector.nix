{ config, ... }:
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sources = {
        journald = {
          type = "journald";
        };
      };
      transforms = {
        journald_remap = {
          type = "remap";
          inputs = [ "journald" ];
          source = ''
            .service_name = ._SYSTEMD_UNIT || ._SYSTEMD_USER_UNIT || .SYSLOG_IDENTIFIER || ._TRANSPORT;
          '';
        };
      };
      sinks = {
        loki = {
          type = "loki";
          inputs = [ "journald_remap" ];
          endpoint = "https://${config.domains.loki}";
          encoding.codec = "json";
          labels = {
            service_name = "{{service_name}}";
            priority = "{{PRIORITY}}";
            boot_id = "{{_BOOT_ID}}";
            host = "{{host}}";
            systemd_unit = "{{_SYSTEMD_UNIT}}";
            systemd_user_unit = "{{_SYSTEMD_USER_UNIT}}";
            syslog_identifier = "{{SYSLOG_IDENTIFIER}}";
            exec = "{{_EXE}}";
            transport = "{{_TRANSPORT}}";
          };
        };
      };
    };
  };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/private/vector";
      mode = "0700";
    }
  ];
}
