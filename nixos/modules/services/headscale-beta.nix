{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.headscale-beta;
  settingsFormat = pkgs.formats.yaml { };
  settingsFile = settingsFormat.generate "headscale.yaml" cfg.settings;
in
{

  options = {
    services.headscale-beta = {
      enable = mkEnableOption "headscale-beta";
      package = mkPackageOption pkgs "headscale-beta" { };
      settings = mkOption {
        description = ''
          Overrides to {file}`config.yaml` as a Nix attribute set.
          Check the [example config](https://github.com/juanfont/headscale/blob/main/config-example.yaml)
          for possible options.
        '';
        type = settingsFormat.type;
        default = { };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."headscale/config.yaml".source = settingsFile;
    environment.systemPackages = [ cfg.package ];

    systemd.services.headscale = {
      description = "headscale coordination server for Tailscale";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ settingsFile ];

      environment.GIN_MODE = "release";

      script = ''
        exec ${cfg.package}/bin/headscale serve
      '';

      serviceConfig = {
        DynamicUser = "yes";
        User = "headscale";
        Group = "headscale";
        Restart = "always";

        StateDirectory = "headscale";
        RuntimeDirectory = "headscale";
        ConfigurationDirectory = "headscale";
        WorkingDirectory = "/var/lib";

        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        UMask = "0077";
      };
    };
  };
}
