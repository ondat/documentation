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
