# Overlay Network

## Motivation

1. To provide connectivity for a hybrid cloud architecture, which consists of multiple cloud providers and local machines.
2. To enable my laptop, github runner, etc., to access private resources.

## Considerations

Here are some considerations for choosing a solution:

- NAT traversal
- Performance (throughput, latency; CPU, memory)
- OIDC integration (and the ability to use without it)
- Self-hosted (both the controller service and the relay service)
- Routes
- DNS
- Operating system support
- Codebase quality
- UI

After comparing **[Tailscale](https://tailscale.com/)**, **[ZeroTier](https://www.zerotier.com/)**,
**[Netmaker](https://netmaker.io/)**, and **[NetBird](https://netbird.io/)**,
I've decided to choose **[NetBird](https://netbird.io/)**.

**Pros**

- It uses kernel-space wireguard, which ensures good performance.
- It's fully open-source and can be easily self-hosted.
- It has an intuitive UI.
- It supports routes. Unlike Tailscale, where nodes advertise their routes by themselves,
  in NetBird, you need to specify the routes in the NetBird Dashboard.
- It supports DNS. You can set a custom DNS server and configure split DNS.
  However, you can't add custom DNS records.
- It has clear API docs.
- It has built-in service accounts.

**Cons**

- The control-plane (management service) can't be deployed without OIDC.

## Known Issues

- **Unable to specify the CIDR for the overlay network.**
  The overlay network CIDR is randomly selected from the CGNAT range.
  This may conflict with existing services,
  especially the Aliyun Metadata Service and the VPC DNS Servers.
  I can create a patch to limit the CIDR range.

- **K3s only has (experimental) built-in support for Tailscale, not NetBird.**
  I can write a flannel extension myself. [^flannel-extension].

[^flannel-extension]: [flannel/pkg/backend/extension/extension.go at v0.26.1 · flannel-io/flannel](https://github.com/flannel-io/flannel/blob/v0.26.1/pkg/backend/extension/extension.go)
