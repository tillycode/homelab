{
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  ## ---------------------------------------------------------------------------
  ## HARDWARE
  ## ---------------------------------------------------------------------------
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  ## ---------------------------------------------------------------------------
  ## NETWORK
  ## ---------------------------------------------------------------------------
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.default.forwarding" = true;
  };

  systemd.network.links = {
    "10-wan0" = {
      matchConfig.Path = "pci-0000:01:00.0";
      linkConfig.Name = "wan0";
    };
    "10-wlan0" = {
      matchConfig.Path = "pci-0000:02:00.0";
      linkConfig.Name = "wlan0";
    };
    "10-lan0" = {
      matchConfig.Path = "pci-0000:04:00.0";
      linkConfig.Name = "lan0";
    };
  };
  systemd.network.networks = {
    "40-wan0" = {
      matchConfig.Name = "wan0";
      linkConfig.Unmanaged = true;
    };
    "40-wlan0" = {
      matchConfig.Name = "wlan0";
      linkConfig.Unmanaged = true;
    };

    "40-lan0" = {
      matchConfig.Name = "lan0";
      DHCP = "no";
      address = [
        "192.168.22.1/24"
      ];
      networkConfig = {
        ConfigureWithoutCarrier = true;
        # IPv4
        DHCPServer = true;
        # IPv6
        IPv6AcceptRA = false;
        DHCPPrefixDelegation = true;
        IPv6SendRA = true;
      };
      dhcpPrefixDelegationConfig = {
        UplinkInterface = "ppp0";
        Announce = true;
        Assign = true;
        Token = "static:::1";
        SubnetId = "auto";
      };
      dhcpServerConfig = {
        ServerAddress = "192.168.22.1/24";
        DNS = [ "192.168.22.1" ];
        PoolOffset = 100;
        PoolSize = 100;
      };
      dhcpServerStaticLeases = [
        {
          # switch
          MACAddress = "24:5A:5F:C6:82:D9";
          Address = "192.168.22.2";
        }
        {
          # AP
          MACAddress = "a4:a9:30:21:28:19";
          Address = "192.168.22.3";
        }
        {
          # hasee01
          MACAddress = "68:1d:ef:52:68:b7";
          Address = "192.168.22.11";
        }
        {
          # hasee02
          MACAddress = "68:1d:ef:52:5a:82";
          Address = "192.168.22.12";
        }
        {
          # hasee03
          MACAddress = "68:1d:ef:52:71:fe";
          Address = "192.168.22.13";
        }
      ];
    };
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "lan0" ];
    externalInterface = "ppp0";
  };
  networking.nftables.tables.clamp-mss = {
    family = "inet";
    content = ''
      	chain forward {
      		type filter hook forward priority mangle; policy accept;
      		iifname "lan0" oifname "ppp0" tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
      	}
    '';
  };
  networking.firewall.allowedUDPPorts = [ 67 ];
  networking.firewall.trustedInterfaces = [ "lan0" ];
}
