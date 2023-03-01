---
title: "How To Clone a Volume"
linkTitle: How To Clone a Volume
---

## Create a Clone of an Existing Volume

[Cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/) a volume is done by referring to an existing volume in the "dataSource" field of the manifest during the creation process.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: clone-of-pvc-1
  namespace: storageos
spec:
  storageClassName: storageos
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  dataSource:
    kind: PersistentVolumeClaim
    name: pvc-1
```

This results in a new volume named `clone-of-pvc-1` which contains a copy of the data in source volume `pvc-1`.

## Create a Clone of an Existing Volume in a Separate Namespace

[Cloning across namespaces](https://kubernetes.io/blog/2023/01/02/cross-namespace-data-sources-alpha/) is available as an alpha feature in Kubernetes v1.26.0.

### Prerequisites

- Kubernetes v1.26.0 or greater.
- Your Kubernetes cluster was deployed with `AnyVolumeDataSource` and `CrossNamespaceVolumeDataSource` feature gates enabled.
- Two namespaces, `dev` and `prod`.

### Create a ReferenceGrant

Let's assume there is an existing volume named `source-pvc` in the `prod` namespace. To clone this volume into the `dev` namespace, we must create a `ReferenceGrant` object in the `prod` namespace that grants access from PVCs in the `dev` namespace.

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-prod-pvc
  namespace: prod
spec:
  from:
  - group: ""
    kind: PersistentVolumeClaim
    namespace: dev
  to:
  - group: ""
    kind: PersistentVolumeClaim
    name: source-pvc
```

### Create a Clone Volume

Create a clone volume in the `dev` namesapce by referring to the source volume name and namespace in the "dataSourceRef" field of the manifest during the creation process.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: clone-of-source-pvc
  namespace: dev
spec:
  storageClassName: storageos
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  dataSourceRef:
    kind: PersistentVolumeClaim
    name: source-pvc
    namespace: prod
```

This results in a new volume named `clone-of-source-pvc` in the `dev` namespace  which contains a copy of the data in `source-pvc` in the `prod` namespace.
