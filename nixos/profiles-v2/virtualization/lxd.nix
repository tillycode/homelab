{
  pkgs,
  lib,
  config,
  ...
}:
let
  zitadelResourceID = "300716890630651980";
  zitadelClientID = "300717015688085580";
  ipv4Address = "10.75.0.1";
  ipv4CIDR = "${ipv4Address}/24";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = ":8443";
        "core.dns_address" = ":853";
        "oidc.audience" = zitadelResourceID;
        "oidc.client.id" = zitadelClientID;
        "oidc.issuer" = "https://login.szp15.com";
        "oidc.groups.claim" = "groups";
        # TODO: TLS pass through?
      };
      networks = [
        {
          name = "lxdbr0";
          type = "bridge";
          project = "default";
          config = {
            "ipv4.address" = ipv4CIDR;
            "ipv6.address" = "auto";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "btrfs";
          description = "";
          config = {
            size = "5GiB";
          };
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              type = "nic";
              name = "eth0";
              network = "lxdbr0";
            };
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
          };
        }
      ];
    };
  };

  ## ---------------------------------------------------------------------------
  ## LOCAL DNS
  ## ---------------------------------------------------------------------------
  systemd.network.networks."10-lxdbr0" = {
    name = "lxdbr0";
    linkConfig = {
      ActivationPolicy = "manual";
    };
    networkConfig = {
      DNS = ipv4Address;
      Domains = "~lxd";
      KeepConfiguration = true;
    };
  };

  ## ---------------------------------------------------------------------------
  ## OIDC INITIALIZATION
  ## ---------------------------------------------------------------------------
  systemd.services.lxd-oidc-init =
    let
      # A script idempotently does the following:
      # 1. Create the "admins" group
      # 2. Add the "server/admin" permission to the "admins" group
      # 3. Create the OIDC group
      # 4. Bind the "admins" group to the OIDC group
      script = pkgs.writeShellApplication {
        name = "unit-script-lxd-oidc-init";
        runtimeInputs = with pkgs; [
          jq
          config.virtualisation.lxd.package
        ];
        text = ''
          set -x

          oidc_admin_group_name=''${LXD_OIDC_ADMIN_GROUP:?missing LXD_OIDC_ADMIN_GROUP}

          if ! group=$(lxc auth group list -f json |
            jq -ec '[.[] | select(.name == "admins")][0]'
          ); then
            lxc auth group create admins
            group=$(lxc auth group list -f json |
              jq -ec '[.[] | select(.name == "admins")][0]')
          fi

          if ! jq -er '[.permissions[]? | select(.entity_type == "server" and .entitlement == "admin")][0]' <<< "$group" >/dev/null; then
            lxc auth group permission add admins server admin
          fi

          if ! oidc_group=$(lxc auth identity-provider-group list -f json |
            jq -ec --arg name "$oidc_admin_group_name" '[.[] | select(.name == $name)][0]'
          ); then
            lxc auth identity-provider-group create "local:$oidc_admin_group_name"
            oidc_group=$(lxc auth identity-provider-group list -f json |
              jq -ec --arg name "$oidc_admin_group_name" '[.[] | select(.name == $name)][0]')
          fi

          if ! jq -er '[.groups[]? | select(. == "admins")][0]' <<< "$oidc_group" >/dev/null; then
            lxc auth identity-provider-group group add "local:$oidc_admin_group_name" admins
          fi
        '';
      };
    in
    {
      description = "LXD OIDC initialization";
      wantedBy = [ "multi-user.target" ];
      requires = [ "lxd.service" ];
      after = [
        "lxd.service"
        "lxd-preseed.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe script;
      };

      environment = {
        LXD_OIDC_ADMIN_GROUP = "${zitadelResourceID}:admins";
      };
    };

  ## ---------------------------------------------------------------------------
  ## PERSISTENCE
  ## ---------------------------------------------------------------------------
  environment.persistence.default.directories = [
    {
      directory = "/var/lib/lxd";
      mode = "0711";
    }
    {
      directory = "/var/lib/lxc";
      mode = "0755";
    }
  ];
}
