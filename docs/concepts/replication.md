---
title: "Replication"
linkTitle: "Replication"
weight: 1
---

Ondat replicates volumes across nodes for data protection and high
availability. Synchronous replication ensures strong consistency for
applications such as databases and Elasticsearch, incurring one network round
trip on writes.

The basic model for Ondat replication is of a master volume with distributed
replicas. Each volume can be replicated between 0 and 5 times, which are
provisioned to 0 to 5 nodes, up to the number of remaining nodes in the cluster.

In this diagram, the master volume `D` was created on node 1, and two replicas,
`D2` and `D3` on nodes 3 and 5.

![Ondat replication](/images/docs/concepts/high-availability.png)

Writes that come into `D` (step 1) are written in parallel to `D2` and `D3`
(step 2). When both replicas and the master acknowledge that the data has been
written (step 3), the write operation return successfully to the application
(step 4).

For most applications, one replica is sufficient (`storageos.com/replicas=1`).

All replication traffic on the wire is compressed using the lz4 algorithm, then
streamed over tcp/ip to target port tcp/5703.

If the master volume is lost, a replica is promoted to master (`D2` or `D3`
above) and a new replica is created and synced on an available node (Node 2 or
4). This is transparent to the application and does not cause downtime.

If a replica volume is lost and there are enough remaining nodes, a new replica
is created and synced on an available node. While a new replica is created and
being synced, the volume's health will be marked as degraded.

If the lost replica comes back online before the new replica has finished
synchronizing, then Ondat will calculate which of the two synchronizing
replicas has the smallest difference compared to the master volume and keep
that replica. The same holds true if a master volume is lost and a replica is
promoted to be the new master. If possible, a new replica will be created and
begin to sync. Should the former master come back online it will be demoted to
a replica and the replica will the smallest difference to the current master
will be kept.

While the replica count is controllable on a per-volume basis, some
environments may prefer to set [default labels on the StorageClass](/docs/reference/labels#storageos-storageclass-labels).

## Delta Sync

Ondat implements a delta sync between a volume master and its replicas.
This means that if a replica for a volume goes offline, that when the replica
comes back online only the regions with changed blocks need to be synchronized.
This optimization reduces the time it takes for replicas to catch up, improving
volume resilience. Additionally, it reduces network and IO bandwidth which can
reduce costs when running in public clouds.

## Topology-Aware Placement

Ondat Topology-Aware Placement is a feature that enforces placement of data
across failure domains to guarantee high availability.

TAP uses default labels on nodes to define failure domains. For instance, an
Availability Zone. For more detail on TAP, check the
[reference page](/docs/reference/tap).

## Failure Modes

Ondat failure modes offer different guarantees with regards to a volume's
mode of operation in the face of replica failure. If the failure mode is not
specified it defaults to `Hard`. Volume failure modes can be dynamically
updated at runtime.

### Hard

Hard failure mode requires that the number of declared replicas matches the
available number of replicas at all times. If a replica fails Ondat will
attempt creation of a new replica for 90 seconds. After 90s if the old replica
is not available and a new replica cannot be provisioned, Ondat cannot
guarantee that the data is stored on the number of multiple nodes requested by
the user. Ondat will therefore set the volume to be read-only.

If a volume has gone read-only there are two stages to making it read-write
again. Firstly, sufficient replicas must be provisioned to match the desired
replica count. Depending on your environment, additional nodes and/or disk
capacity may be required for this. Secondly, the volume must be remounted -
necessitating pod deletion/recreation in Kubernetes.

```bash
storageos.com/failure-mode: hard
```

**Number of nodes required for hard failure mode**

When a node fails, a new replica is provisioned and synced as described above.
To ensure that a new replica can always be created, an additional node should
be available. To guarantee high availability using `storageos.com/failure-mode:
hard`, clusters using volumes with 1 replica must have at least 3 storage
nodes. When using volumes with 2 replicas, at least 4 storage nodes, 3
replicas, 5 nodes, etc.

Minimum number of storage nodes = 1 (primary) + N (replicas) + 1

### Soft

Soft failure mode allows a volume to continue serving I/O even when a replica
goes offline and a new replica fails to provision. So long as there are not
less than max(1,  n-1) available replicas where n is the number of replicas for
the volume.

For example, if a volume with 2 replicas loses 1 replica, then I/O would
continue to be served since 1 replica remaining >= max(1, 1). If a volume with
1 replica loses 1 replica, then I/O would halt after 90 seconds since 0
replicas remaining < max(1, 0).

```bash
storageos.com/failure-mode: soft
```

**Number of nodes required for soft failure mode**

To ensure that a `storageos.com/failure-mode: soft
` volume is highly available, clusters using volumes with 1 replica must have at
least 2 storage nodes. When using volumes with 2 replicas, at least 3 storage
nodes, 3 replicas, 3 nodes, etc.

Minimum number of storage nodes = 1 (primary) + N (replicas)

### Threshold

Threshold failure mode allows the user to set the minimum required number of
online replicas for a volume. For example for a volume with 2 replicas, setting
the threshold to 1 would allow a single replica to be offline, whereas setting
threshold to 0 would allow 2 replicas to be offline.

```bash
storageos.com/failure-mode: (0-5)
```

**Number of nodes required for threshold failure mode**

The minimum number of nodes for a `threshold` volume is determined by the
threshold that is set.

Minimum number of storage nodes = 1 (primary) + T (threshold)

### AlwaysOn

AlwaysOn failure mode allows all replicas for a volume to be offline and keeps
the volume writeable. A volume with failure mode AlwaysOn will continue to
serve I/O regardless of how many replicas it currently has. This mode should be
used with caution as it effectively allows for only a single copy of the data
to be available.

```bash
storageos.com/failure-mode: alwayson
```

**Number of nodes required for AlwaysOn failure mode**

A `storageos.com/failure-mode: alwayson` volume is highly available albeit at
the cost of reliability. The minimum node count here is 1 as the loss of all
replicas will be tolerated.

Minimum number of storage nodes = 1 (primary)

For details about how to use the labels on the VolumesCheck, see the [failure modes operations](/docs/operations/failure-modes) page.
