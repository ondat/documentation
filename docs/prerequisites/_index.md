---
title: "Prerequisites"
linkTitle: "Prerequisites"
weight: 300
description: >
  Key prerequisites and system requirements to deploy Ondat.
---

## Overview

- This page provides information on the requirements that are required to successfully run Ondat on your container orchestrator. Ensure that you have met the requirements before attempting to do an Ondat deployment.






## Minimum requirements

One machine with the following:

* Minimum two core with 4GB RAM
* Linux with a 64-bit architecture
* Kubernetes 1.20+ with an N-4 release support where N is the current k8s release.
* Container Runtime Engine: CRI-O, Containerd or Docker 1.10+ with [mount propagation](/docs/prerequisites/mountpropagation) enabled
* The necessary ports should be open. See the [ports and firewall settings](/docs/prerequisites/firewalls)
* [Etcd cluster](/docs/prerequisites/etcd) for Ondat
* A mechanism for [device presentation](/docs/prerequisites/systemconfiguration)

## Recommended

* Prepare a cluster with minimum of 5 nodes when running etcd within Kubernetes for replication and high availability; 3 nodes if etcd is outside Kubernetes or a self-eval cluster
* [Install the Ondat CLI](/docs/reference/cli/)
* If using Helm2, make sure the tiller ServiceAccount has enough privileges to create resources such as Namespaces, ClusterRoles, etc. For instance, following this [installation procedure](https://v2.helm.sh/docs/using_helm/#role-based-access-control)
* System clocks synchronized using NTP or similar methods. While our distributed consensus algorithm does not require synchronised clocks, it does help to more easily correlate logs across multiple nodes
* A PID cgroup limit of 32768
* Some aspects of product operation require kernel support for IPv6. See the [IPv6 prequisites](/docs/prerequisites/ipv6) page
