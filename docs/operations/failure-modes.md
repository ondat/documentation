---
title: "How To Use Failure Modes"
linkTitle: How To Use Failure Modes
---

## Overview

Ondat failure modes offer different guarantees with regards to a volume's mode of operation in the face of replica failure.

- If the failure mode is not specified it defaults to `hard`.
- Volume failure modes can be dynamically updated at runtime.

> 💡  For more information on how the replication and failure mode features work, review the [Replication](/docs/concepts/replication) feature page.

### Example - Set Failure Mode to `soft` for a Volume

The failure mode for a specific volume can be set using a label on a PVC or it can be set as a parameter on a custom Ondat [StorageClass](/docs/operations/storageclasses).

> 💡 A PVC definition takes precedence over a StorageClass definition.

Below is an example of a PVC resource that ensures that 2 replica volumes will be available and sets a `soft` failure mode.

```yaml
# Create a "my-vol-1" PVC with 2 volume replicas and "soft" failure mode enabled.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-vol-1
  labels:
      storageos.com/replicas: "2"           # 2 volumes replicas will be available.
      storageos.com/failure-mode: "soft"    # "soft" failure mode is enabled.
spec:
  storageClassName: "storageos"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```

Once the PVC resource has been successfully created, review and confirm that the `storageos.com/failure-mode: "soft"` and `storageos.com/replicas: "2"` labels have been applied.

```bash
# Get the labels applied to the "my-vol-1" PVC.
kubectl get pvc --output=wide --show-labels --namespace=default

NAME                                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
my-vol-1                            Bound    pvc-9477f989-8a60-4d10-8407-99bad90b29a3   5Gi        RWO            storageos      63s   Filesystem   storageos.com/failure-mode=soft,storageos.com/replicas=2
```
