---
title: "Volume Resize"
linkTitle: Volume Resize
---

Ondat supports offline resize of volumes, either through editing a PVC
storage request, or by updating the volume config via the CLI or UI. A volume
cannot be resized while it is in use. To ensure that it is not, for a resize
operation to take place the volume must not be attached to a node. This
requires that any pods using a volume be scaled down for the resize to take
place.

Note, that Ondat only supports increasing volume size. For more
information on how the resize works, see our [Resize Concepts](/docs/concepts/volumes#volume-resize) page.

### Resizing a Volume

In order to resize a PVC the storage request field must be updated.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-1
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

The Volume must be offline for this to take effect. Therefore, before
performing the operation, scale down any pods using the volume. This will
ensure that it is not in use.

In order to edit a PVC you can use `kubectl edit` or `kubectl apply` to make
changes.

> ⚠️ Resizing a volume without updating the PVC directly will NOT result in
> the PVC being updated. The methods below are included for completeness. In
> Kubernetes environments editing the PVC is the preferred method for resizing
> a volume.

To resize a volume using the Ondat CLI use the `volume update` command

```bash
$ storageos update volume size pvc-a47cfa03-cc92-4ec9-84ab-00e5516c64fa 10GiB
Name:                                 pvc-a47cfa03-cc92-4ec9-84ab-00e5516c64fa
ID:                                   925e667f-91d3-465a-9391-8fdb56d0c9ff
Size:                                 11 GB
Description:
AttachedOn:
Replicas:                             1x ready
Labels:
  - csi.storage.k8s.io/pv/name        pvc-a47cfa03-cc92-4ec9-84ab-00e5516c64fa
  - csi.storage.k8s.io/pvc/name       pvc-1
  - csi.storage.k8s.io/pvc/namespace  default
  - foo                               bar
  - pool                              default
  - storageos.com/replicas            1

Volume pvc-a47cfa03-cc92-4ec9-84ab-00e5516c64fa (925e667f-91d3-465a-9391-8fdb56d0c9ff) updated. Size changed.
```

To resize a volume using the Ondat UI, navigate to the volumes section and
click the edit pencil in order to update the volume config.

![Ondat Resize](/images/docs/operations/resize/resize-vol.png)
