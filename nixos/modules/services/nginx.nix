{ config, lib, ... }:
let
  cfg = config.services.nginx;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.networking) enableIPv6;

  sniServerNameConfig = lib.pipe cfg.sniHosts [
    (lib.mapAttrsToList (
      name: sniHost:
      lib.map (serverName: ''
        ${serverName} ${name};
      '') sniHost.serverNames
    ))
    lib.flatten
    lib.concatStrings
  ];

  toUpstreamParameter =
    key: value:
    if builtins.isBool value then lib.optionalString value key else "${key}=${toString value}";
  sniUpstreamConfig = lib.pipe cfg.sniHosts [
    (lib.mapAttrsToList (
      name: upstream: ''
        upstream ${name} {
          ${lib.pipe upstream.servers [
            (lib.mapAttrsToList (
              name: server: ''
                server ${name} ${lib.concatStringsSep " " (lib.mapAttrsToList toUpstreamParameter server)};
              ''
            ))
            lib.concatStrings
          ]}
        }
      ''
    ))
    lib.concatStrings
  ];
  sniListenConfig = lib.pipe cfg.defaultSSLListenAddresses [
    (lib.map (addr: ''
      listen ${
        if lib.hasPrefix "unix:" addr then addr else "${addr}:${toString cfg.defaultSSLListenPort}"
      } ${lib.optionalString cfg.enableProxyProtocol "proxy_protocol"};
    ''))
    lib.concatStrings
  ];

  hasSSL = v: v.listen == [ ] && (v.onlySSL || v.enableSSL || v.addSSL || v.forceSSL || v.rejectSSL);
in
{
  ## ---------------------------------------------------------------------------
  ## OPTIONS
  ## ---------------------------------------------------------------------------
  options.services.nginx = {
    enableProxyProtocol = mkEnableOption "proxy protocol support for default SSL listener";
    proxyProtocolTrustedIPs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of trusted IPs for the proxy protocol.";
    };
    defaultSSLListenAddresses = mkOption {
      type = types.listOf types.str;
      default = cfg.defaultListenAddresses;
      defaultText = lib.literalExpression "config.services.nginx.defaultListenAddresses";
      description = ''
        List of addresses to listen for the default SSL listener.

        Only takes effect if either `enableSNIProxy` or `enableProxyProtocol` is set.
      '';
    };
    enableSNIProxy = mkEnableOption "Enable SNI-based proxy provided by nginx stream module";
    sniHosts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              serverNames = mkOption {
                type = types.listOf types.str;
                description = ''
                  List of server names to match for this SNI host.
                '';
                default = [ name ];
              };
              default = mkEnableOption "Makes this sniHost the default.";
              servers = mkOption {
                type = types.attrsOf (
                  types.submodule {
                    freeformType = types.attrsOf (
                      types.oneOf [
                        types.bool
                        types.int
                        types.str
                      ]
                    );
                  }
                );
                description = ''
                  Defines the address and other parameters of the upstream servers.
                  See [the documentation](https://nginx.org/en/docs/stream/ngx_stream_upstream_module.html#upstream)
                  for the available parameters.
                '';
                default = { };
              };
            };
            config = lib.mkIf (config.default) {
              serverNames = [ "default" ];
            };
          }
        )
      );
      description = "Defines a group of servers to use as proxy target.";
      default = { };
    };
    sniExtraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        These lines go to the end of the stream server block verbatim.
      '';
    };
  };

  options.services.nginx.virtualHosts = lib.mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          config.extraConfig = lib.mkMerge [
            (lib.mkIf (cfg.enableSNIProxy && hasSSL config) ''
              set_real_ip_from unix:;
              real_ip_header proxy_protocol;
            '')
            (lib.mkIf (!cfg.enableSNIProxy && cfg.enableProxyProtocol && hasSSL config) ''
              ${lib.concatStrings (
                lib.map (ip: ''
                  set_real_ip_from ${ip};
                '') cfg.proxyProtocolTrustedIPs
              )}
              real_ip_header proxy_protocol;
            '')

          ];
        }
      )
    );
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableSNIProxy {
      services.nginx.streamConfig = ''
        map $ssl_preread_server_name $name {
          hostnames;
          ${sniServerNameConfig}
        }
        ${sniUpstreamConfig}
        server {
          ${sniListenConfig}
          ssl_preread on;
          ${lib.optionalString cfg.enableProxyProtocol (
            lib.concatStrings (
              lib.map (ip: ''
                set_real_ip_from ${ip};
              '') cfg.proxyProtocolTrustedIPs
            )
          )}
          proxy_pass $name;
          proxy_protocol on;
          ${cfg.sniExtraConfig}
        }
      '';

      services.nginx.defaultListen =
        lib.singleton {
          addr = "0.0.0.0";
          ssl = false;
        }
        ++ lib.optional enableIPv6 {
          addr = "[::0]";
          ssl = false;
        }
        ++ lib.singleton {
          addr = "unix:/run/nginx/nginx-ssl.sock";
          ssl = true;
          proxyProtocol = true;
        };
      services.nginx.sniHosts."nginx" = {
        serverNames = lib.pipe cfg.virtualHosts [
          (lib.filterAttrs (_: virtualHost: hasSSL virtualHost))
          (lib.mapAttrsToList (
            name: virtualHost:
            lib.singleton (if virtualHost.serverName != null then virtualHost.serverName else name)
            ++ virtualHost.serverAliases
          ))
          lib.flatten
        ];
        servers = {
          "unix:/run/nginx/nginx-ssl.sock" = { };
        };
      };
    })
    (lib.mkIf (!cfg.enableSNIProxy && cfg.enableProxyProtocol) {
      services.nginx.defaultListen =
        lib.singleton {
          addr = "0.0.0.0";
          ssl = false;
        }
        ++ lib.optional enableIPv6 {
          addr = "[::0]";
          ssl = false;
        }
        ++ lib.map (addr: {
          addr = addr;
          ssl = true;
          proxyProtocol = true;
        }) cfg.defaultSSLListenAddresses;
    })
  ];
}
