---
title: "How To Create Custom Storage Classes"
linkTitle: "How To Create Custom Storage Classes"
---

## Overview

[Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) in Kubernetes are used to link [`PersistentVolumeClaim`s (PVCs)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) with a backend storage provisioner such as Ondat.

- A `StorageClass` defines parameters to pass to the provisioner, which, in the case of Ondat, can be translated into behaviour applied to the volumes that will be provisioned. End users can create more than one custom Ondat `StorageClass` with different [feature labels](/docs/concepts/labels/).
- By default, the Ondat Operator creates a `storageos` `StorageClass` when Ondat is deployed for the first time. End users can get more information about the `StorageClass` object created by running the following commands below:

```bash
# Get more informaton about the "storageos" StorageClass object.
kubectl get storageclasses storageos

NAME        PROVISIONER         RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
storageos   csi.storageos.com   Delete          Immediate           true                   13m

# Describe the "storageos" StorageClass object.
kubectl describe storageclasses storageos

Name:            storageos
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"labels":{"app":"storageos","app.kubernetes.io/component":"storageclass"},"name":"storageos"},"parameters":{"csi.storage.k8s.io/fstype":"ext4","csi.storage.k8s.io/secret-name":"storageos-api","csi.storage.k8s.io/secret-namespace":"storageos"},"provisioner":"csi.storageos.com","reclaimPolicy":"Delete","volumeBindingMode":"Immediate"}

Provisioner:           csi.storageos.com
Parameters:            csi.storage.k8s.io/fstype=ext4,csi.storage.k8s.io/secret-name=storageos-api,csi.storage.k8s.io/secret-namespace=storageos
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

- Below is the YAML output of the `storageos` StorageClass object after removing metadata details:

```yaml
# "storageos" StorageClass.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  labels:
    app: storageos
    app.kubernetes.io/component: storageclass
  name: storageos
parameters:
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
provisioner: csi.storageos.com
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

> 💡 A `PersistentVolumeClaim` (PVC) definition takes precedence over a `StorageClass` definition.

## Creating Custom Ondat Storage Classes

The following examples will demonstrate how to create custom Ondat storage classes with feature labels to fit end user's use cases.

- End users can also find more custom Ondat storage classes examples in the [Ondat Use Cases](https://github.com/ondat/use-cases) project repository that is available on GitHub.

```bash
# Clone the repository.
git clone git@github.com:ondat/use-cases.git

# Navigate into the directory
cd custom-storage-classes/

# List the StorageClass manifests in the directory.
ls -lah
```

### Example - Create a StorageClass that Enables Volume Replication

Below is an example Ondat StorageClass definition called `ondat-replicated` that uses the [Volume Replication](/docs/concepts/replication/) feature label.

```yaml
# Create the "ondat-replicated" StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-replicated
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  storageos.com/replicas: "2"                           # Create 2 replica volumes.
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
EOF
```

```bash
# Review and confirm that "ondat-replicated" was created.
kubectl get sc | grep "ondat-replicated"
```

For a detailed demonstration of how to use the Volume Replication feature with persistent volumes, review the [How To Use Volume Replication](/docs/operations/replication/) operations page.

### Example - Create a StorageClass that Enables Volume Replication & Topology-Aware Placement (TAP)

Below is an example Ondat StorageClass definition called `ondat-tap` that uses the [Volume Replication](/docs/concepts/replication/) and [Topology-Aware Placement (TAP)](/docs/concepts/tap/) feature labels.

```yaml
# Create the "ondat-tap" StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-tap
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "2"                          # Create 2 replica volumes.
  storageos.com/topology-aware: "true"                 # Enable TAP (default looks for "topology.kubernetes.io/zone=" on nodes)
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
EOF
```

```bash
# Review and confirm that "ondat-tap" was created.
kubectl get sc | grep "ondat-tap"
```

For a detailed demonstration of how to use the Volume Replication & Topology-Aware Placement features with persistent volumes, review the [How To Enable Topology-Aware Placement (TAP)](/docs/operations/tap/) operations page.

### Example - Create a StorageClass that Enables Volume Replication, Topology-Aware Placement (TAP) & Volume Encryption

Below is an example Ondat StorageClass definition called `ondat-replicated-tap-encrypted` that uses the [Volume Replication](/docs/concepts/replication/), [Topology-Aware Placement (TAP)](/docs/concepts/tap/) and [Volume Encryption](/docs/concepts/encryption/) feature labels.

```yaml
# Create the "ondat-encryption" StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-replicated-tap-encrypted
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  storageos.com/replicas: "2"                             # Create 2 replica volumes.
  storageos.com/encryption: "true"                        # Enable volume encryption.
  storageos.com/topology-aware: "true"                    # Enable TAP (default looks for "topology.kubernetes.io/zone=" on nodes)
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
EOF
```

```bash
# Review and confirm that "ondat-replicated-tap-encrypted" was created.
kubectl get sc | grep "ondat-replicated-tap-encrypted"
```

For a detailed demonstration of how to use the Volume Encryption feature with persistent volumes, review the [How To Enable Data Encryption For Volumes](/docs/operations/encryption/) operations page.

### Example - Create a StorageClass that Enables Data Compression

Below is an example Ondat StorageClass definition called `ondat-compressed` that uses the [Data Compression](/docs/concepts/replication/) feature label.

```yaml
# Create the "ondat-compressed" StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-compressed
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  storageos.com/nocompress: "false"                     # Enable compression of data-at-rest and data-in-transit.
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
EOF
```

For a detailed demonstration of how to use the compression for persistent volumes, review the [How To Enable Data Compression](/docs/operations/compression/) operations page.
