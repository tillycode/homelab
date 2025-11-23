{
  modulesPath,
  lib,
  config,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./pppd.nix
    ./sing-box.nix
    ./bird.nix
  ];
  config = lib.mkMerge [
    ## ---------------------------------------------------------------------------
    ## HARDWARE
    ## ---------------------------------------------------------------------------
    {

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

      users.users.root.hashedPassword = "$y$j9T$5H0k9lXNhiB/RWu34ZqmR/$tS3OgHLomQFWEeP515WYo8AFKYjIw0gG.BZurM6FMR8";
      networking.firewall.logRefusedConnections = false;
      networking.firewall.logRefusedPackets = true;
      networking.firewall.logRefusedUnicastsOnly = false;
    }
    ## ---------------------------------------------------------------------------
    ## NETWORK
    ## ---------------------------------------------------------------------------
    {
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
        wan = {
          id = 2;
          interface = "bond0";
        };
        lan = {
          id = 3;
          interface = "bond0";
        };
        svc = {
          id = 4;
          interface = "bond0";
        };
      };

      systemd.network.networks."40-eth0" = {
        linkConfig.MTUBytes = 9000;
      };
      systemd.network.networks."40-eth1" = {
        linkConfig.MTUBytes = 9000;
      };
      systemd.network.networks."40-wlan0" = {
        matchConfig.Name = "wlan0";
        linkConfig.Unmanaged = true;
      };
      systemd.network.networks."40-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig.MTUBytes = 9000;
        networkConfig.IPv6AcceptRA = false;
      };
    }
    {
      # lan interface
      systemd.network.networks."40-lan" = {
        matchConfig.Name = "lan";
        addresses = [
          {
            Address = "192.168.23.1/24";
          }
        ];
        linkConfig.MTUBytes = 1500;
        networkConfig = {
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
          ServerAddress = "192.168.23.1/24";
          # DNS = [ "192.168.23.1" ];
          EmitRouter = false; # TODO: testing
          PoolOffset = 100;
          PoolSize = 100;
        };
        dhcpServerStaticLeases = [
          {
            # AP
            MACAddress = "a4:a9:30:21:28:19";
            Address = "192.168.23.2";
          }
          {
            # printer
            MACAddress = "90:31:4b:98:9b:5b";
            Address = "192.168.23.4";
          }
        ];
      };
      networking.firewall.extraInputRules = ''
        meta nfproto ipv4 iifname lan udp sport 68 udp dport 67 accept comment "DHCPv4 client"
      '';
    }
    {
      # svc interface
      systemd.network.networks."40-svc" = {
        matchConfig.Name = "svc";
        linkConfig.MTUBytes = 9000;
        address = [ "10.9.0.1/24" ];
        networkConfig.IPv6AcceptRA = false;
      };
    }
    {
      # NAT and firewall
      boot.kernel.sysctl = {
        "net.ipv6.conf.all.forwarding" = true;
        "net.ipv6.conf.default.forwarding" = true;
      };
      networking.nat = {
        enable = true;
        externalInterface = "ppp0";
        internalInterfaces = [
          "lan"
          "svc"
        ];
      };
      networking.firewall = {
        filterForward = true;
        # temporary allow all traffic from lan to svc
        extraForwardRules = ''
          iifname "lan" oifname "svc" accept
        '';
      };
      networking.nftables.tables.clamp-mss = {
        family = "inet";
        content = ''
          	chain forward {
          		type filter hook forward priority mangle; policy accept;
          		tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
          	}
        '';
      };
      networking.firewall.interfaces =
        let
          cfg = {
            inherit (config.networking.firewall)
              allowedTCPPorts
              allowedTCPPortRanges
              allowedUDPPorts
              allowedUDPPortRanges
              ;
          };
        in
        {
          default = lib.mapAttrs (name: value: [ ]) cfg;
          lan = cfg;
          svc = cfg;
        };
    }
    {
      # DNS
      services.resolved.extraConfig = ''
        DNSStubListenerExtra=10.9.0.1
      '';
      networking.firewall.allowedUDPPorts = [ 53 ];
    }
  ];
}
