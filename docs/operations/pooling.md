---
title: "How To Use Ondat Storage Pooling"
linkTitle: How To Use Ondat Storage Pooling"
---

## Overview

Ondat's Storage Pooling lets you control the storage backends that your
workloads run on. For more information on the feature, please review the
[Storage Pooling](/docs/concepts/pooling) feature page.

## How To Use

### Preparing your Drives

Drives will need to be added to the desired Kubernetes nodes and mounted inside `/var/lib/storageos/`.

Example:
If you install an nvme drive and want it to only be used by a storage pool you may mount it to `/var/lib/storageos/nvme1`.

If you install an nvme drive and want it to be used by any volume you may mount it to `/var/lib/storageos/data/dev2`. Drives mounted like this can still be used by storage pools. Any drives mounted which conform to the pattern '`/var/lib/storageos/data/dev[0-9]+`' will also be used by Ondat volumes on that node that do not use the storage pool, as that is our default storage location.

### Creating a Storage Pool

Storage pools are a [Kubernetes custom resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) and can be applied as such. The custom resource has a few fields that should be supplied.

The storage pool controller will create a `StorageClass` from the storage pool, so the standard storage class fields should be set (for example `allowVolumeExpansion`, `parameters`, `reclaimPolicy` and `volumeBindingMode`). These fields will fallback to their defaults if not set.

The other field that must be set is the `nodeDriveMap`, this defines the drives that are in the storage pool and specifies which nodes they're on and where they're mounted.

Example:

```
apiVersion: api.storageos.com/v1
kind: Pool
metadata:
  name: "my-fast-storage-pool"
spec:
  nodeDriveMap:
    worker-1:
    - "/var/lib/storageos/nvme1"
    - "/var/lib/storageos/nvme2"
    worker-2:
    - "/var/lib/storageos/really-fast-nvme"
    worker-3:
    - "/var/lib/storageos/data/dev1"
  volumeBindingMode: Immediate
  allowVolumeExpansion: true
  parameters:
    csi.storage.k8s.io/fstype: ext4
    storageos.com/replicas: 1
```

Above defines a storage pool that has 4 drives total, 2 on worker-1 (mounted to `/var/lib/storageos/nvme1` and `/var/lib/storageos/nvme2` respectively), 1 on worker-2 (mounted to `/var/lib/storageos/really-fast-nvme`) and 1 on worker-3 (mounted to `/var/lib/storageos/data/dev1`).

The resulting `StorageClass` will by default use `ext4`, allow volume expansion, immediately bind PVs and have 1 replica. As it The drive on worker-3 will be used for all volumes that land on that node, as well as any volumes that use the storage pool.

> Note: Volumes still need to be replicated to utilise more than a single node's drives.

### Using a Storage Pool

When a storage pool is created Ondat's storage pool controller will create a `StorageClass`, named in the form `storageos-<namespace>-<storage pool name>`.

Any PVCs that use the resulting `StorageClass` will use the storage pool and therefore will only write data to the drives specified by the storage pool.

It's important to note that volumes that use a storage pool will only host primaries and replicas on nodes that are part of the pool.
If there's not enough nodes in the pool to host a volume the following error will be applied to the PVC's status: `not enough suitable nodes for the requested number of deployment`.

### Updating a Storage Pool

Storage pools support the following updates:

- Adding a new drive, on an existing node, to the pool
- Adding a new node to the pool (and therefore adding one or more new drives)

In both cases the new drives will only be used for new volumes, existing volumes will not start using the new drives.

To update a pool simply edit the `Pool` CR and apply the changes.

> Note: Removing drives or nodes from a pool is not supported. Instead create a new pool with fewer drives/nodes.

### Deleting a Storage Pool

Storage pools can only be deleted if they're not in use (i.e no volumes are using the storage class created by the pool). A finalizer is used to ensure this.

If a pool is not in use and it is deleted the storage pool controller will cleanup the related storage class.
