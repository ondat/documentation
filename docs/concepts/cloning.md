---
title: "Ondat Cloning"
linkTitle: "Ondat Cloning"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.10.0` or greater.

The Ondat Cloning feature adds support for specifying existing PVCs in the dataSource field to indicate a user would like to clone a Volume.

### What is a Clone?

A **clone** is defined as a duplicate of an existing Kubernetes Volume that can be consumed as any standard Volume would be.

### Why use Cloning:

TODO.

### How Does It Work?

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

The result is a new Volume with the name clone-of-pvc-1 that has the exact same content as the specified source pvc-1.

### Current Scope & Limitations

The Ondat Cloning feature has the following limitations:

1. Cloning volumes across namespaces is not supported.
1. A clone Volume must be the same size as the Volume which it is attempting to clone.
1. A clone Volume must have the same filesystem as the Volume which it is attempting to clone.
