---
title: "StorageClasses"
linkTitle: StorageClasses
---

[StorageClasses](https://kubernetes.io/docs/concepts/storage/storage-classes/)
in Kubernetes are used to link PVCs with a backend storage provisioner - for
instance, Ondat. A StorageClass defines parameters to pass to the
provisioner, which in the case of Ondat can be translated into behaviour
applied to the Volumes. Many StorageClasses can be provisioned to apply
different feature labels to the Ondat Volumes.

By default the Ondat Operator installs the `storageos` StorageClass at
bootstrap of Ondat. You can define its name in the Ondat Cluster Resource.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
allowVolumeExpansion: true
provisioner: csi.storageos.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
```

StorageClasses can be created to define default labels for Ondat volumes,
but also to map to any semantic aggregation of volumes that suits your use
case, whether there are different roles (dev, staging, prod), or a
StorageClass maps to a team or customer using the cluster.

## Examples

You can find the basic examples in the Ondat use-cases repository, in
the `00-basic/v2.5.storageclass-and-later` directory.

```bash
git clone https://github.com/storageos/use-cases.git storageos-usecases
cd storageos-usecases/00-basic/v2.5.storageclass-and-later
```

### Replicated Storage Class

StorageClass definition in `v2-storageclass-replicated.yaml`.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: storageos-rep
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "1"
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
```

That StorageClass can be used by a PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-vol-1
spec:
  storageClassName: "ondat-replicated" # Ondat StorageClass
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

The above StorageClass has the `storageos.com/replicas` label set. This
label tells Ondat to create a volume with a replica. Adding Ondat
feature labels to the StorageClass ensures all volumes created with the
StorageClass have the same labels.

You can also choose to add the label in the PVC definition rather than the
StorageClass. The PVC definition takes precedence over the StorageClass.

### Topology Aware Storage Class

StorageClass that enables [Topology Aware Placement](/docs/reference/tap)
and replication with [soft mode](/docs/operations/failure-modes):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: storageos-rep-tap
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "2"
  storageos.com/failure-mode: "soft"
  storageos.com/topology-aware: "true"
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
```

### Encrypted volumes Storage Class

StorageClass that enables encryption and replication for volumes.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: storageos-rep-enc
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "1"
  storageos.com/encryption: "true"
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
```
