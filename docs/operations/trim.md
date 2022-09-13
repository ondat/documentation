---
title: "How To Use TRIM with Volumes"
linkTitle: How To Use TRIM with Volumes
---

## Overview

Ondat volumes support [TRIM/UNMAP](https://en.wikipedia.org/wiki/Trim_%28computing%29) by default for all uncompressed volumes.

- [Compression](/docs/concepts/compression/) is disabled by default from release version `v2.2.0`, therefore Ondat volumes will support TRIM/UNMAP calls - unless compression is explicitly enabled. By trimming an Ondat volume, this will release space that has been taken up by deleted blocks in Ondat volume blob files.
- TRIM can either be called periodically through [`fstrim`](https://man7.org/linux/man-pages/man8/fstrim.8.html) or continuously using the [`-o discard`](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_file_systems/discarding-unused-blocks_managing-file-systems#enabling-online-block-discard_discarding-unused-blocks) [`mount`](https://man7.org/linux/man-pages/man8/mount.8.html) option.
- The recommended discard method to use is [periodic discarding](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_file_systems/discarding-unused-blocks_managing-file-systems#types-of-block-discard-operations_discarding-unused-blocks).

> 💡 For more information on TRIM support with Ondat, review the [Volumes](/docs/concepts/volumes/#trim) feature page.

### Example - Using `fstrim` To Conduct Periodic Discarding

In order to TRIM a volume you can run `fstrim` against the Ondat volume filesystem. The volume filesystem will be presented at the mount point for the Ondat device.

- Below is an example that shows the effect of `fstrim` on an Ondat volume mounted on `/mnt`.

```bash
# A Ondat volume with some data written to it.
ls -ls --block-size 1 /var/lib/storageos/data/dev1/vol.211585.*.blob | awk '!/^total/ {total = total + $1}END{print total}'

8.85838e+09

# A Ondat volume is mounted on "/mnt".
df -h /mnt

Filesystem                                                         Size  Used Avail Use% Mounted on
/var/lib/storageos/volumes/v.bbfae475-3ce3-4238-bf33-cfe88256d813  4.9G  520M  4.1G  12% /mnt

# Delete a file from the volume, sync all filesystems to ensure data has been written and then "fstrim" the volume filesystem.
rm /mnt/test; sync; fstrim /mnt

# Check and confirm that the space in the blob files, (and thus space in the backend filesystem) has been reclaimed.
ls -ls --block-size 1 /var/lib/storageos/data/dev1/vol.211585.*.blob | awk '!/^total/ {total = total + $1}END{print total}'

469700608
```

### Example - Automate Periodic Discarding with `fstrim`

Discarding unused blocks can be automated by running `fstrim` against mounted Ondat volumes.

- When running in Kubernetes, the [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) component is responsible for mounting volumes into pods so the mount endpoints for pods are accessible under `/var/lib/kubelet/pods`.
- Ondat volume mounts appear as mounts from `/var/lib/storageos/volumes/v.${DEPLOYMENT_ID}` on `/var/lib/kubelet/pods/${POD_UID}/volumes/kubernetes.io~csi/${PV_ID}/mount`.

```bash
mount | awk '/storageos\/volumes\/v.*/'

/var/lib/storageos/volumes/v.4364e143-865e-45d7-a4a5-e0d964d9e200 on /var/lib/kubelet/pods/29ec4774-71d6-4ba3-b275-f80b47e9f6af/volumes/kubernetes.io~csi/pvc-357a9baa-7b74-49db-8d63-c540b5129ad8/mount type ext4 (rw,relatime,stripe=32)
/var/lib/storageos/volumes/v.8dc449a4-1fb5-43d8-86d0-e18916a85c18 on /var/lib/kubelet/pods/6bb92a8f-afb5-48c8-837c-56f45e15e5c4/volumes/kubernetes.io~csi/pvc-2d30a2ba-2663-4036-bb1e-e795f226d6f3/mount type ext4 (rw,relatime,stripe=32)

mount | awk '/storageos\/volumes\/v.*/ {print $3}'

/var/lib/kubelet/pods/29ec4774-71d6-4ba3-b275-f80b47e9f6af/volumes/kubernetes.io~csi/pvc-357a9baa-7b74-49db-8d63-c540b5129ad8/mount
/var/lib/kubelet/pods/6bb92a8f-afb5-48c8-837c-56f45e15e5c4/volumes/kubernetes.io~csi/pvc-2d30a2ba-2663-4036-bb1e-e795f226d6f3/mount
```

- With this information in mind, it is therefore possible to use Kubernetes to automate periodic discarding with `fstrim`. The `SYS_ADMIN` capability is required to run `fstrim` and propagation of mounts from the host to the container will allow any new Ondat mounts to be picked up by the UNMAP pod.
- Below is an example that shows how a Kubenetes pod could be used to run `fstrim` against Ondat volumes mounted on the same node that the pod is scheduled on.

```yaml
# Create a pod that conducts periodic discarding of unused blocks with `fstrim`.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: Pod
metadata:
  name: discard
spec:
  containers:
    - name: fstrim
      command: ["/bin/bash"]
      image: ubuntu:latest
      args: ["-c","for mount in $(mount | awk '/storageos\\/volumes\\/v.*/ {print $3}'); do if [ -d ${mount}  ]; then fstrim -v ${mount}; fi; sleep 5; done"]
      securityContext:
        capabilities:
          add:
            - SYS_ADMIN
      volumeMounts:
      - mountPath: /var/lib/kubelet
        mountPropagation: HostToContainer
        name: kubelet-dir
  volumes:
  - hostPath:
      path: /var/lib/kubelet
      type: Directory
    name: kubelet-dir
EOF
```

- Alternatively a [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) on the node itself could be used to `fstrim` mounted Ondat volumes using similar logic.

> ⚠️ Trimming can be an I/O intensive operation so care should be taken when running `fstrim` against multiple volumes at once.

### Example - Using the `-o discard` Mount Option To Conduct Continuous Discarding

Ondat volumes can be mounted using the `-o discard` `mount` option which will automatically send TRIM commands when blocks are removed.
> ⚠️ Caution should be used enabling this option as testing has shown that volumes with a lot of churn can experience performance degradation. The pathological case being a volume that is continuously filled with small files that are then all deleted, repeatedly.

The `discard` option can be enabled as a `StorageClass` or `PersistentVolume`. Enabling `discard` as a `StorageClass` option will result in all volumes
provisioned with that StorageClass being mounted with `discard`, whereas setting the option through a `PersistentVolume` will set discarding on a per-volume basis.

- Below is an exmaple that uses a custom Ondat `StorageClass` to provision StorageClass below would provision xfs volumes with the `discard` option
enabled by default.

```yaml
# Use the discard mount option for all Ondat volumes created with this StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ondat-discard
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
mountOptions:
  - discard                           # add the "discard" option here
EOF
```

```bash
# Review and confirm that "ondat-discard" was created.
kubectl get sc | grep "ondat-discard"
```

- To enable discarding for an existing Ondat `PersistentVolume`, end users can apply the `discard` option under the `spec.mountOptions` section.

```yaml
# Create a "pvc-discard" PVC that uses the default Ondat StorageClass.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-discard
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```

```bash
# Get more information on "pvc-discard" and its PV name and resource.
kubectl get pvc pvc-discard --output=wide --show-labels --namespace=default

NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE   LABELS
pvc-discard   Bound    pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528   5Gi        RWO            storageos      3m45s   Filesystem   <none>

kubectl get pv | grep "pvc-discard"

pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528   5Gi        RWO            Delete           Bound    default/pvc-discard          storageos               4m3s
```

- Edit `pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528` and add the `discard` mount option to the resource.

```bash
# Edit the "pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528"
kubectl edit pv pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528

# apply the discard mount option...

  mountOptions:
  - discard

# save and exit from the editor.
```

- Check and review that the `discard` option has been successfully applied to the `pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528` persistent volume.

```bash
kubectl get pv pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528 --output=yaml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: csi.storageos.com
  creationTimestamp: "2022-08-02T16:29:57Z"
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528
  resourceVersion: "121296"
  uid: e8eef812-6091-43b4-aad3-4faa5bfaed29
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: pvc-discard
    namespace: default
    resourceVersion: "119349"
    uid: c24d5506-53ae-436a-8e07-5ed6cbefa528
  csi:
    controllerExpandSecretRef:
      name: storageos-api
      namespace: storageos
    controllerPublishSecretRef:
      name: storageos-api
      namespace: storageos
    driver: csi.storageos.com
    fsType: ext4
    nodePublishSecretRef:
      name: storageos-api
      namespace: storageos
    nodeStageSecretRef:
      name: storageos-api
      namespace: storageos
    volumeAttributes:
      csi.storage.k8s.io/pv/name: pvc-c24d5506-53ae-436a-8e07-5ed6cbefa528
      csi.storage.k8s.io/pvc/name: pvc-discard
      csi.storage.k8s.io/pvc/namespace: default
      storage.kubernetes.io/csiProvisionerIdentity: 1659453485570-8081-csi.storageos.com
      storageos.com/nocompress: "true"
    volumeHandle: 88ff9cd9-6f29-4d79-b216-8d8c573bdef5/2f85ce13-7383-4f9d-bb0b-dcbc3e195bf3
  mountOptions:
  - discard
  persistentVolumeReclaimPolicy: Delete
  storageClassName: storageos
  volumeMode: Filesystem
status:
  phase: Bound
```
