---
title: "Prerequisites"
linkTitle: Prerequisites
weight: 300
description: >
  Ondat requirements to be executed. Hardware, Network rules, Operative
  System Distribution, Kernel modules, etc.
---

# Prerequisites

## Minimum requirements:

One machine with the following:

1. Minimum two core with 4GB RAM.
1. Linux with a 64-bit architecture.
1. Kubernetes 1.18 to 1.22
1. Container Runtime Engine: CRI-O, Containerd or Docker 1.10+ with [mount propagation](/docs/prerequisites/mountpropagation) enabled.
1. The necessary ports should be open. See the [ports and firewall settings](/docs/prerequisites/firewalls).
1. [Etcd cluster](/docs/prerequisites/etcd) for Ondat
1. A mechanism for [device presentation](/docs/prerequisites/systemconfiguration).

## Recommended:

1. At least three nodes for replication and high availability.
1. Kubernetes 1.18 to 1.22
1. [Install the Ondat CLI](/docs/reference/cli/).
1. If using Helm2, make sure the tiller ServiceAccount has enough privileges to
   create resources such as Namespaces, ClusterRoles, etc. For instance, following this [installation
   procedure](https://v2.helm.sh/docs/using_helm/#role-based-access-control).
1. System clocks synchronized using NTP or similar methods. While our
   distributed consensus algorithm does not require synchronised clocks, it
   does help to more easily correlate logs across multiple nodes.
1. A PID cgroup limit of 32768.
1. Some aspects of product operation require kernel support for IPv6. See the
   [IPv6 prequisites](/docs/prerequisites/ipv6) page.
