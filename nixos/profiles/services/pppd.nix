{ lib, pkgs, ... }:
let
  wanIface = "wan0";
  pppIface = "ppp0";
in
{
  ## ---------------------------------------------------------------------------
  ## CONFIGURATION
  ## ---------------------------------------------------------------------------
  services.pppd = {
    enable = true;
    peers.dialer = {
      autostart = true;
      config = ''
        plugin pppoe.so

        nic-${wanIface}
        name ad85606778
        ifname ${pppIface}

        usepeerdns
        persist
        maxfail 0
        holdoff 5
        up_sdnotify

        defaultroute
      '';
    };
  };
  systemd.services.pppd-dialer = {
    preStart = ''
      ${lib.getExe' pkgs.iproute2 "ip"} link set ${wanIface} up
    '';
    serviceConfig = {
      Type = "notify";
    };
    environment = {
      NIX_REDIRECTS = lib.mkForce "/var/run=/run/pppd:/etc/ppp/resolv.conf=/run/pppd/resolv.conf";
    };
  };

  systemd.network.networks."40-${pppIface}" = {
    matchConfig.Name = pppIface;
    linkConfig.RequiredForOnline = "routable";
    DHCP = "yes";
    networkConfig = {
      KeepConfiguration = "yes";
      IPv6AcceptRA = true;
    };
    dhcpV6Config = {
      PrefixDelegationHint = "::/60";
      UseDelegatedPrefix = true;
      WithoutRA = "solicit";
    };
  };

  ## ---------------------------------------------------------------------------
  ## SECRETS
  ## ---------------------------------------------------------------------------
  sops.secrets."ppp/password" = {
    restartUnits = [ "pppd-dialer.service" ];
  };
  environment.etc."ppp/pap-secrets".text = ''
    ad85606778 * @/run/secrets/ppp/password
  '';

  ## ---------------------------------------------------------------------------
  ## HACK
  ## ---------------------------------------------------------------------------
  # sync /run/pppd/resolv.conf to systemd-resolved
  systemd.paths."pppd-resolv-conf" = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/run/pppd/resolv.conf";
  };
  systemd.services.pppd-resolv-conf = {
    enableStrictShellChecks = true;
    script =
      let
        overridePath = "/run/systemd/network/40-${pppIface}.network.d";
      in
      ''
        rm -f ${overridePath}/99-pppd-resolv-conf.conf
        readarray -t nameservers < <(sed -ne 's/^nameserver\s\+//p' /run/pppd/resolv.conf 2>/dev/null)

        if [[ ''${#nameservers[@]} -gt 0 ]]; then
          echo "updating DNS servers: ''${nameservers[*]}"
          mkdir -p ${overridePath}
          IFS=$'\n'
          printf '[Network]\n%s\n' "''${nameservers[*]/#/DNS=}" > ${overridePath}/99-pppd-resolv-conf.conf
        else
          echo "clearing DNS servers"
        fi
        networkctl reload
        networkctl reconfigure ${lib.escapeShellArg pppIface}
      '';
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    requires = [ "sys-subsystem-net-devices-${pppIface}.device" ];
    after = [ "sys-subsystem-net-devices-${pppIface}.device" ];
  };
}
