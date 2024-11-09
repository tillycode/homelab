# Dev Cluster (WIP)

## Overview

The dev cluster is a group of self-hosted _virtual machines_.
They are different from the production machines in the following ways:

- They may be frequently created and destroyed for testing purposes.
- They may be deployed imperatively instead of declaratively.

We use **LXD** to manage the dev cluster.

## Infrastructure for the Dev Cluster

### Network

I'd like to have a flat overlay network for all the nodes including the dev cluster.
Each node, no matter it is a _physical machine_, _container_, or _virtual machine_, should be able to communicate with each other.
To achieve this, we need to assign unique IP addresses to each node.
Currently, I'm using the following IP ranges:

| IPv4 CIDR                          | Description             |
| ---------------------------------- | ----------------------- |
| 10.42.0.0/16                       | Kubernetes pod IPs      |
| 10.43.0.0/16                       | Kubernetes service IPs  |
| 192.168.0.0/16                     | _Reserved for LANs_     |
| 100.100.100.200/32                 | Aliyun Metadata Service |
| 100.100.2.136/32, 100.100.2.138/32 | Aliyun DNS Servers      |
| 198.18.0.0/15                      | Fake IPs for proxy      |
| 10.88.0.0/16                       | Podman bridge           |
| 172.17.0.0/16                      | Docker bridge           |
| 169.254.0.0/16                     | Link-local addresses    |

Currently, `10.212.4.0/24` is used for the LXD bridge network.

### DNS
