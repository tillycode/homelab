# Overlay Network

## Motivation

The primary goal for the overlay network is to provide a **flat network** for
all kinds of nodes, including self-hosted VMs, VPSs, PCs, and Kubernetes pods.

## Considerations

Here are some considerations for the overlay network:

| Feature                 | Priority | Description                              | Use Case                                               |
| ----------------------- | -------- | ---------------------------------------- | ------------------------------------------------------ |
| **Route Advertisement** | P1       | Advertise route between nodes            | 1. Access VMs and containers 2. join multiple networks |
| **NAT Traversal**       | P1       | Direct connections if preferred          | Save traffic costs and improve performance             |
| **Custom DNS**          | P1       | Support custom DNS servers               | Discover nodes and services by their domain names      |
| **Performance**         | P2       | Kernel-space implementation is preferred |                                                        |
| **Self-hosting**        | P2       | Provide official open-source solutions   |                                                        |
| **Portability**         | P2       | Provide clients for major OSs            |                                                        |
| **OIDC Integration**    | P3       |                                          |                                                        |
| **Codebase Quality**    | P3       |                                          |                                                        |
| **UI**                  | P3       |                                          |                                                        |

Note that route advertisement is a important feature. It allows a host node
to advertise its VMs and containers to other nodes. This is essential for
Kubernetes pods to communicate with each other without double encapsulation [^flannel-extension].
It also allows multiple networks, including other overlay networks, to be joined together.

Here are some popular choices: **[ZeroTier](https://www.zerotier.com/)**,
**[Tailscale](https://tailscale.com/)**, **[NetBird](https://netbird.io/)**,
**[Netmaker](https://netmaker.io/)**, and **[Nebula](https://github.com/slackhq/nebula)**.

## Experiments

At first, I chose Tailscale. It has some limitations:

- **Self-hosting**: Tailscale control-plane is closed-source. Luckily,
  there is an open-source alternative called **[Headscale](https://github.com/juanfont/headscale)**.
- **Performance**: It uses userspace wireguard, which may have performance issues.
- **UI**: As there is no official open-source control-plane, there is also no official open-source UI.
  Luckily, there are a few community UIs available.

Then, I found NetBird. So I decided to give it a try. It is competitive with Tailscale in many aspects.
However, I found it has a significant limitation:

- **NAT traversal**: When I have two VMs in one PC, and accessing them from another PC
  under the same NAT, Tailscale can always establish a direct IPv6 connection.
  NetBird, however, sometimes uses a relay server, and sometimes establishes
  a IPv4 connection by hole-punching.

After these experiments, I decided to keep using Tailscale and Headscale.

[^flannel-extension]: [flannel/pkg/backend/extension/extension.go at v0.26.1 · flannel-io/flannel](https://github.com/flannel-io/flannel/blob/v0.26.1/pkg/backend/extension/extension.go)
