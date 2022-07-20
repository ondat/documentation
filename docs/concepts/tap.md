---
title: "Ondat Topology-Aware Placement (TAP)"
linkTitle: "Ondat Topology-Aware Placement (TAP)"
weight: 1
---
## Overview

> 💡 This feature is available in release `v2.5.0` or greater.

Ondat Topology-Aware Placement is a feature that enforces placement of data across failure domains to guarantee high availability.

Ondat TAP uses default [labels on nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#built-in-node-labels) to define failure domains - for instance, an [Availability Zone](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). However, the key label used to segment failure domains can be defined by the user per node. Lastly, Ondat TAP is an opt-in feature per volume.

### How does Ondat Topology-Aware Placement Work?

Ondat's Topology-Aware Placement attempts to distribute sensitive data across different failure domains. Hence, a primary volume and its replicas are scattered across failure domains - that is implemented following a [best effort algorithm](https://en.wikipedia.org/wiki/Best-effort_delivery). 
- In case that Ondat TAP rules can't be fulfilled the placement algorithm will attempt a best approach placement (even if new replicas are in the same failure domain).
- The best effort placement allows the system to place replicas on the same failure domains when a full domain has failed catastrophically. Hence, the system self heals as fast as possible without waiting for the nodes on the failed domain to recover.

It is the user's responsibility to rebalance the data when the failed domain has recovered its availability. That can be achieved by recreating the replicas of a volume.

> 💡 Future versions of Ondat will facilitate the procedure by allowing a volume drain.

### Advantages of using Ondat Topology-Aware Placement (TAP)

Deploying a stateful application on a clusters with multiple nodes without Ondat TAP enabled can result in suboptimal placement for [high availability.](https://en.wikipedia.org/wiki/High_availability) Not enabling Ondat TAP can cause following problems:
- Unschedulable pods due to resource, affinity, and taint issues when a full failure domain experiences a failure.
- Volume replicas placed within the same zone as a primary volume.

![Ondat Topology-Aware Placement](/images/docs/concepts/tap.png)

### How to use Ondat Topology-Aware Placement?

Topology-Aware Placement can be enabled by applying the label `storageos.com/topology-aware=true` to a PVC or as a parameter of its StorageClass.
- For more information on how to enable Ondat Topology-Aware Placement for your volumes, review the [Ondat Topology-Aware Placement](/docs/operations/tap) operations page.

### Understanding Topology Domains

A topology domain is a set of nodes. The domain is identified by a label, which can be defined by the user.
- The default label that Ondat uses to segment nodes in failure domains is >> `topology.kubernetes.io/zone`. 
- However, you can define your own topology key by setting the key string in the [Ondat feature label](docs/concepts/labels/) >> `storageos.com/topology-key`.


### Ondat Failure Modes & Topology-Aware Placement

Failure modes are a complimentary feature of the Topology-Aware Placement functionality. Failure modes allow you to define how many replicas of a volume can become unavailable before the volume is marked as read-only. 
- For more information on how to Failure Modes work , review the [Ondat Topology-Aware Placement](/docs/concepts/replication) feature page.

For example, assuming that your cluster has three topology zones, `A`, `B` and `C`, and your deployment has a master and two replicas, Ondat will attempt to place one volume in each topology zone.
- If zone `A` fails, I/O operations to your volume will stop completely - if the Failure Mode is `hard`. 
- If the Failure Mode is `soft` - I/O operations will continue while volume failover is in progress, and a new replica will be placed in an operational zone. 
- Note that if zone `A` recovers, the cluster will **not** automatically rebalance.

The `soft` failure mode will not tolerate the failure of multiple replicas at once, and will suspend I/O operations in this case. 
- If you wish to tolerate more than one failed replica, then you can set this as an integer using the `<integer>` label.
- If individual nodes within a topology zone fail, the replicas will fail over to other nodes within that zone. Once nodes in the zone are exhausted, placement will revert to best-effort.