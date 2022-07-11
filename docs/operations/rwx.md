---
title: "ReadWriteMany"
linkTitle: ReadWriteMany
---

> ⚠️ An Ondat licence is required to create RWX Volumes. RWX is available in the free Ondat Community Edition. For more information, please visit [Licensing](/docs/operations/licensing/#types-of-licenses).

Ondat supports ReadWriteMany (RWX) [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
Persistent Volumes. A RWX PVC can be used simultaneously by many Pods in the
same Kubernetes namespace for read and write operations.

Ondat RWX Volumes are based on a shared filesystem.

To create a ReadWriteMany (RWX) volume with Ondat, create a Persistent
Volume Claim (PVC) with an access mode of `ReadWriteMany` (see the
[First PVC](/docs/operations/firstpvc) documentation for
examples of creating standard PVCs with Ondat).

The following YAML manifest files provide an example:

A 5Gi PVC with the Ondat `storageClassName` of `storageos`, with an
`accessMode` of `ReadWriteMany`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

A Deployment of 3 Pods, each of which consume this PVC:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared
  labels:
    app: shared
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shared
  template:
    metadata:
      labels:
        app: shared
    spec:
      containers:
        - name: debian
          image: debian:9-slim
          command: ["/bin/sleep"]
          args: [ "3600" ]
          volumeMounts:
            - mountPath: /mnt/
              name: v1
      volumes:
        - name: v1
          persistentVolumeClaim:
            claimName: pvc-rwx
```

After creating the above resources, the PVC (here named `pvc-rwx`) should be
bound and show an access mode of RWX:

```bash
$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-rwx     Bound    pvc-59f7a152-8342-415c-a6ca-1cbb463410ab   5Gi        RWX            storageos      60s
```

Ensure that the Deployment Pods are running:

```
$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
shared-1771418926-7o5ns   1/1     Running   0          1m
shared-1771418926-r18az   1/1     Running   0          1m
shared-1771418926-ds8f7   1/1     Running   0          1m
```

The NFS-Ganesha service that exposes the Ondat volume as RWX can now be
viewed, showing the cluster IP of the service, and the default NFS port
(2049).

```bash
$ kubectl get svc
NAME                                        TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
kubernetes                                  ClusterIP   10.96.0.1     <none>        443/TCP    120m
pvc-59f7a152-8342-415c-a6ca-1cbb463410ab    ClusterIP   10.107.10.0   <none>        2049/TCP   1m
```

Features of the NFS volume can also be examined in the Ondat UI.
Under `Volumes`, the `Attachment` column shows an `nfs` tag. The
`Volume Details` section provides information about the NFS Volume, such
as the service endpoint and the node on which the underlying Volume is
attached.

## Changing the Squash mode

As part of the 2.8 release, a change was made so that users can change the
squash mode that is used with the RWX shares.
Historically, all shares were exported with a `Squash = All` mode of operation.
This was requested by most customers as the idea of identity in a container 
based deployment is very abstract.
There is now a label that can applied to make this tunable, users can now add 
`storageos.com/nfs-squash = root|rootuid|all|none` to their volumes (where 
all is still the default behaviour still) to adjust this setting.

As an example, the above PVC definition can be labelled as:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
  labels:
    storageos.com/nfs-squash: "rootuid"
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

This will squash only the root user to `root` leaving other UID operations intact.
