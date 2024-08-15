{
  lib,
  self,
  config,
  ...
}:
let
  data = self.lib.data.hosts.${config.networking.hostName} or null;
in
{
  misc.node-facts = {
    addresses = {
      public_ipv4 = data.addresses.public_ipv4 or null;
      public_ipv6 = data.addresses.public_ipv6 or null;
      overlay_ipv4 = data.addresses.overlay_ipv4 or null;
      overlay_ipv6 = data.addresses.overlay_ipv6 or null;
    };
    resources = {
      disks = data.resources.disks or [ ];
    };
  };
}
