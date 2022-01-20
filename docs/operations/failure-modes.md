---
title: "Failure Modes"
linkTitle: Failure Modes
---

For more information about replication and failure modes, see our
[Replication concepts page](/docs/concepts/replication).

The failure mode for a specific volume can be set using a label on a PVC or it
can be set as a parameter on a [StorageClass](/docs/operations/storageclasses). The PVC definition takes precedence over
the StorageClass.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-vol-1
  labels:
      storageos.com/replicas: "2"
      storageos.com/failure-mode: "soft"
spec:
  storageClassName: "storageos"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```


## Failure Modes

Ondat failure modes offer different guarantees with regards to a volume's
mode of operation in the face of replica failure. If the failure mode is not
specified it defaults to `Hard`. Volume failure modes can be dynamically
updated at run time.

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



