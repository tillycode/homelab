{ ... }:
{
  # FIXME: sing-box deprecates `inet4_address` and `inet6_address` options
  #   in favor of the new `address` option in v1.10.0.
  #   See https://sing-box.sagernet.org/configuration/inbound/tun/#address.
  #
  # ### DNS
  #
  # There are

  # By default, DNS are processed in the following orders
  # 1. If the DNS query is initiated by an `outbound`, e.g., to resolve the
  #    IP address of a proxy server, the query is handled by `local`
}
