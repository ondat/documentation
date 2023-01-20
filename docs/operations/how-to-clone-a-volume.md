---
title: "How To Clone a Volume"
linkTitle: How To Clone a Volume
---

## Create a Clone of an Existing Volume

The Kubernetes [Volume Cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/) feature provides users with a mechanism to create a clone Volume by adding a dataSource that references an existing Volume.

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

The result is a new Volume with the name clone-of-pvc-1 that has the exact same content as the specified source Volume `pvc-1`.
