---
title: "Topology-Aware Placement"
linkTitle: Topology-Aware Placement
---

Ondat Topology-Aware Placement is a feature that enforces placement of data
across failure domains to guarantee high availability. Topology-Aware Placement
(TAP) is available from Ondat v2.5+.

TAP uses default labels on nodes to define failure domains. For instance, an
Availability Zone. However, the key label used to segment failure domains can
be defined by the user per node. Also, TAP is an opt in feature per volume.

## Benefits of enabling the Topology-Aware Placement (TAP) feature

Deploying a stateful application on a clusters with multiple nodes without TAP
enabled can result in suboptimal placement for high availability. Not enabling
TAP can cause following problems:

* unschedulable pods due to resource, affinity, and taint issues when a full
  failure domain experiences a failure
* volume replicas placed within the same zone as a primary volume

![tap](/images/docs/concepts/tap.png)

## Enabling Topology-Aware Placement

Topology-Aware Placement can be enabled by applying the label
`storageos.com/topology-aware=true` to a PVC or as a parameter of its
StorageClass.

## Topology Domains

A topology domain is a set of nodes. The domain is identified by a label, which
can be defined by the user. The default label that Ondat uses to segment nodes
in failure domains is `topology.kubernetes.io/zone`. However, you can define
your own topology key by setting the key string in the label
`storageos.com/topology-key`.

To enable TAP on your volumes, follow the
[TAP operations](/docs/operations/tap) page.

## Behaviour

The Topology-Aware Placement attempts to distribute sensitive data across
different failure domains. Hence, a primary volume and its replicas are
scattered across failure domains. That is implemented following a best effort
algorithm. In case that the TAP rules can't be fulfilled the placement
algorithm will attempt a best approach placement (even if new replicas
are in the same failure domain).
The best effort placement allows the system to place replicas on the same
failure domains when a full domain has failed catastrophically. Hence, the
system self heals as fast as possible without waiting for the nodes on the
failed domain to recover.

It is the user's responsibility to rebalance the data when the failed domain
has recovered its availability. That can be achieved by recreating the replicas
of a volume. Future versions of Ondat will facilitate the procedure by allowing
a volume drain.

## Failure Modes

Failure modes are a complimentary feature of the Topology-Aware Placement
functionality. Failure modes allow you to define how many replicas of a volume
can become unavailable before the volume is marked as read-only. For more
information , see the
[failure mode concepts page](/docs/concepts/replication#failure-modes).

For example, assuming that your cluster has three topology zones, A, B and C,
and your deployment has a master and two replicas, Ondat will attempt to
place one volume in each topology zone.

If zone A fails, I/O to your volume will stop completely if the Failure Mode is
`hard`. If the Failure Mode is `soft`, I/O will continue while volume failover
is in progress, and a new replica will be placed in an operational zone. Note
that if zone A recovers, the cluster will **not** automatically rebalance.

The `soft` failure mode will not tolerate the failure of multiple replicas at
once, and will suspend I/O in this case. If you wish to tolerate more than one
failed replica, then you can set this as an integer using the `<integer>`label.

If individual nodes within a topology zone fail, the replicas will fail over to
other nodes within that zone. Once nodes in the zone are exhausted, placement
will revert to best-effort.
