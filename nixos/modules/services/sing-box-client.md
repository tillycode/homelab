# SagerNet/sing-box &mdash; Transparent Proxy Setup

## DNS

### DNS handler

There are 4 DNS handlers, they are:

| DNS Handler         | Description                           | Use case                                  |
| ------------------- | ------------------------------------- | ----------------------------------------- |
| :house: `local`     | Using domestic DNS server             | domestic domains                          |
| :zap: `remote`      | Return FakeIP                         | `A` and `AAAA` record for foreign domains |
| :airplane: `google` | Using Google DNS server through proxy | other DNS records for foreign domains     |
| :x: `block`         | Return empty response                 | Ads and tracking domains                  |

Only packets with FakeIp destination are routed to the sing-box TUN interface.
Other packets are routed as usual.
This can greatly increase the performance.

### DNS process rules

1. :house: if initiated from sing-box
2. :house: if clash mode is `Direct`
3. :zap: if clash mode is `Global` and type is `A` or `AAAA`
4. :airplane: if clash mode is `Global`
5. :x: if matches _custom block rules_
6. :house: if matches _custom local rules_
7. :zap: if if type is `A` or `AAAA`
8. :airplane: otherwise

Rule 2-4 is available only if clash support is enabled.
Typical _custom block rules_ are ads and tracking domains.
Typical _custom local rules_ are private IP, GeoIP cn, and Geosite cn.

## Inbound

There are 2 inbounds, they are:

| Inbound | Description       | Use case            |
| ------- | ----------------- | ------------------- |
| TUN     | Transparent Proxy |                     |
| Mixed   | HTTP/Socks Proxy  | if TUN doesn't work |

## Outbound

| Outbound  | Description             |
| --------- | ----------------------- |
| `dns-out` | DNS handler shown above |
| `block`   |                         |
| `direct`  |                         |
| _custom_  |                         |

### Outbound handler

1. `dns-out` if it is a DNS request
2. _custom rules_
