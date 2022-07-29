---
title: "Ondat Replication"
linkTitle: "Ondat Replication"
weight: 1
---

## Overview

### How Does Ondat's Replication Work?

Ondat replicates volumes across nodes for data protection and high availability. Synchronous [replication](https://en.wikipedia.org/wiki/Replication_%28computing%29) ensures strong consistency for applications such as databases and message queues, incurring one network round trip on writes.

- The basic model for Ondat replication is of a master volume with distributed replicas. Each volume can be replicated between `0` and `5` times, which are provisioned to `0` to `5` nodes, up to the number of remaining nodes in the cluster.
- In this diagram, the master volume `D` was created on node `1`, and two replicas, `D2` and `D3` on nodes `3` and `5`.

![Ondat Replication Diagram](/images/docs/concepts/high-availability.png)

- **[Step 1]** >> Data from the application is written to the master volume first (`D`).
- **[Step 2]** >> Data is then written in parallel to the replica volumes (`D2` & `D3`).
- **[Step 3]** >> Master and replica volumes all acknowledge that data has been received and written
- **[Step 4]** >> A successful write operation is returned to the application.

For most applications, one replica is sufficient `storageos.com/replicas=1`. All replication traffic on the wire is compressed using the [LZ4 (compression algorithm)](https://en.wikipedia.org/wiki/LZ4_%28compression_algorithm%29), then streamed over `TCP/IP` to target port `TCP/5703`.

- If the master volume is lost, a replica is promoted to master (`D2` or `D3` above) and a new replica is created and synced on an available node (node `2` or `4`). This is transparent to the application and does not cause downtime.
- If a replica volume is lost and there are enough remaining nodes, a new replica is created and synced on an available node. While a new replica is created and being synced, the volume's health will be marked as degraded.
- If the lost replica comes back online before the new replica has finished synchronising, then Ondat will calculate which of the two synchronising replicas has the smallest difference compared to the master volume and keep that replica.
- The same holds true if a master volume is lost and a replica is promoted to be the new master. If possible, a new replica will be created and begin to sync. Should the former master come back online it will be demoted to a replica and the replica will the smallest difference to the current master will be kept.
- While the replica count is controllable on a per-volume basis, some environments may prefer to set [default labels on the StorageClass](/docs/concepts/labels).

### Ondat's Delta Sync Algorithm

Ondat implements a delta sync between a volume master and its replicas.

- This means that if a replica for a volume goes offline, that when the replica comes back online only the regions with changed blocks need to be synchronised.
- This optimisation reduces the time it takes for replicas to catch up, improving volume resilience.
- Additionally, it reduces network and I/O bandwidth which can reduce costs when running in public clouds.

### Ondat Topology-Aware Placement (TAP)

Ondat Topology-Aware Placement (TAP) is a feature that enforces placement of data across failure domains to guarantee high availability.

- TAP uses default labels on nodes to define failure domains. For instance, an [Availability Zone (AZ)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).

For more information on Topology-Aware Placement feature, review the [Ondat Topology-Aware Placement](/docs/concepts/tap) feature page.

## Ondat Failure Modes

> 💡 This feature is available in release `v2.4.0` or greater.

Ondat failure modes offer different guarantees with regards to a volume's mode of operation in the face of replica failure. If the failure mode is not specified it defaults to `Hard`. Volume failure modes can be dynamically updated at runtime.

### `hard` Failure Mode

`hard` failure mode requires that the number of declared replicas matches the available number of replicas at all times.

- If a replica fails Ondat will attempt creation of a new replica for 90 seconds. After 90s if the old replica is not available and a new replica cannot be provisioned, Ondat cannot guarantee that the data is stored on the number of multiple nodes requested by the user. Ondat will therefore set the volume to be read-only.
- If a volume has gone read-only there are two stages to making it read-write again. Firstly, sufficient replicas must be provisioned to match the desired replica count. Depending on your environment, additional nodes and/or disk capacity may be required for this. Secondly, the volume must be remounted - necessitating pod deletion/recreation in Kubernetes.

 ```bash
 storageos.com/failure-mode: hard
 ```

**Number Of Nodes Required For A `hard` Failure Mode Setup**

- When a node fails, a new replica is provisioned and synced as described above. To ensure that a new replica can always be created, an additional node should be available.
- To guarantee high availability using `storageos.com/failure-mode: hard`, clusters using volumes with `1` replica must have at least `3` storage nodes.
- When using volumes with `2` replicas, at least `4` storage nodes, `3` replicas, `5` nodes, and so on.
- `Minimum number of storage nodes = 1 (primary) + N (replicas) + 1`

### `soft` Failure Mode

`soft` failure mode allows a volume to continue serving I/O even when a replica goes offline and a new replica fails to provision.

- So long as there are `not less than max(1, N-1)` available replicas where `N` is the number of replicas for the volume.
- For example, if a volume with `2` replicas loses `1` replica, then I/O would continue to be served since `1` replica remaining `>= max(1, 1)`.
    > ⚠️ If a volume with `1` replica loses `1` replica, then I/O would halt after `90` seconds since `0`
replicas remaining `< max(1, 0)`.

 ```bash
 storageos.com/failure-mode: soft
 ```

**Number Of Nodes Required For A `soft` Failure Mode Setup**

- To ensure that a `storageos.com/failure-mode: soft` volume is highly available, clusters using volumes with `1` replica must have at least `2` storage nodes.
- When using volumes with `2` replicas, at least `3` storage nodes, `3` replicas, 3 nodes, etc.
- `Minimum number of storage nodes = 1 (primary) + N (replicas)`

### `threshold` Failure Mode

`threshold` failure mode allows the user to set the minimum required number of online replicas for a volume.

- For example for a volume with `2` replicas, setting the threshold to `1` would allow a single replica to be offline, whereas setting threshold to `0` would allow `2` replicas to be offline.

 ```bash
 storageos.com/failure-mode: (0-5)
 ```

**Number Of Nodes Required For A `threshold` Failure Mode Setup**

- The minimum number of nodes for a `threshold` volume is determined by the threshold that is set.
- `Minimum number of storage nodes = 1 (primary) + T (threshold)`

### `alwayson` Failure Mode

`alwayson` failure mode allows all replicas for a volume to be offline and keeps the volume writeable. A volume with failure mode AlwaysOn will continue to serve I/O regardless of how many replicas it currently has.

- This mode should be used with caution as it effectively allows for only a single copy of the data to be available.

 ```bash
 storageos.com/failure-mode: alwayson
 ```

**Number Of Nodes Required For A `alwayson` Failure Mode Setup**

- A `storageos.com/failure-mode: alwayson` volume is highly available albeit at the cost of reliability.
- The minimum node count here is `1` as the loss of all replicas will be tolerated.
- `Minimum number of storage nodes = 1 (primary)`.

For details about how to use the labels on the VolumesCheck, see the [Failure Modes](/docs/operations/failure-modes) operations page.
