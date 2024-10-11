{ lib, pkgs, ... }:
let
  package = pkgs.tailscale-patched;
  domain = "derper0.szp15.com";
  port = 2100;
in
{
  # based on NixOS/nixpkgs#306533
  systemd.services.tailscale-derper = {
    serviceConfig = {
      ExecStart = "${lib.getOutput "derper" package}/bin/derper -a :${toString port} -c /var/lib/derper/derper.key --hostname=${domain} --verify-clients";
      DynamicUser = true;
      Restart = "always";
      RestartSec = "5sec";
      StateDirectory = "derper";
      Type = "simple";
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = null;
      LockPersonality = true;
      NoNewPrivileges = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx.virtualHosts."derper0.szp15.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:2100";
      proxyWebsockets = true;
    };
  };
}
