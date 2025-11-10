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
  systemd.network.links = {
    "10-eth0" = {
      matchConfig.Path = "pci-0000:02:00.0";
      linkConfig.Name = "eth0";
    };
    "10-eth1" = {
      matchConfig.Path = "pci-0000:03:00.0";
      linkConfig.Name = "eth1";
    };
    "10-wlan0" = {
      matchConfig.Path = "pci-0000:04:00.0";
      linkConfig.Name = "wlan0";
    };
  };
  networking.bonds.bond0 = {
    interfaces = [
      "eth0"
      "eth1"
    ];
    driverOptions = {
      mode = "802.3ad";
      lacp_rate = "fast";
      xmit_hash_policy = "layer3+4";
      miimon = "100";
    };
  };

  networking.vlans = {
    lan = {
      id = 3;
      interface = "bond0";
    };
    wan = {
      id = 2;
      interface = "bond0";
    };
    svc = {
      id = 4;
      interface = "bond0";
    };
  };

  # lan interface
  systemd.network.networks."40-lan" = {
    matchConfig.Name = "lan";
    DHCP = "no";
    addresses = [
      {
        Address = "192.168.22.1/24";
        DuplicateAddressDetection = "none";
      }
    ];
    linkConfig = {
      RequiredForOnline = "no-carrier";
    };
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
      UplinkInterface = ":auto";
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
        # AP
        MACAddress = "a4:a9:30:21:28:19";
        Address = "192.168.22.2";
      }
      {
        # printer
        MACAddress = "90:31:4b:98:9b:5b";
        Address = "192.168.22.4";
      }
    ];
  };

  users.users.root.hashedPassword = "$y$j9T$5H0k9lXNhiB/RWu34ZqmR/$tS3OgHLomQFWEeP515WYo8AFKYjIw0gG.BZurM6FMR8";

  # boot.kernel.sysctl = {
  #   "net.ipv6.conf.all.forwarding" = true;
  #   "net.ipv6.conf.default.forwarding" = true;
  # };

  # networking.nat = {
  #   enable = true;
  #   internalInterfaces = [ "lan0" ];
  #   externalInterface = "ppp0";
  # };
  # networking.nftables.tables.clamp-mss = {
  #   family = "inet";
  #   content = ''
  #     	chain forward {
  #     		type filter hook forward priority mangle; policy accept;
  #     		iifname "lan0" oifname "ppp0" tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
  #     	}
  #   '';
  # };
  # networking.firewall.allowedUDPPorts = [ 67 ];
  # networking.firewall.trustedInterfaces = [ "lan0" ];
}
