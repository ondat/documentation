---
title: "TRIM"
linkTitle: TRIM
---

Ondat volumes support TRIM/Unmap by default for all uncompressed volumes.
Ondat creates uncompressed volumes by default so all of these volumes will
support TRIM/Unmap calls. TRIM'ing an Ondat volume will release space taken
up by deleted blocks in the Ondat volume blob files.

TRIM can either be called periodically via `fstrim` or continously using the
`-o discard` mount option. Ondat recommends using periodic discard.

## Periodic Discard

In order to TRIM a volume you can run `fstrim` against the volume filesystem.
The volume filesystem will be presented at the mount point for the Ondat
device.

The example below shows the effect of `fstrim` on an Ondat volume mounted on
`/mnt`.
```
# A Ondat volume with some data written to it.
$ ls -ls --block-size 1 /var/lib/storageos/data/dev1/vol.211585.*.blob | awk '!/^total/ {total = total + $1}END{print total}'
8.85838e+09

# A Ondat volume is mounted on /mnt
$ df -h /mnt
Filesystem                                                         Size  Used Avail Use% Mounted on
/var/lib/storageos/volumes/v.bbfae475-3ce3-4238-bf33-cfe88256d813  4.9G  520M  4.1G  12% /mnt

# Delete a file from the volume, sync all filesystems to ensure data has been written and then fstrim the volume filesystem
$ rm /mnt/test; sync; fstrim /mnt

# Observe that the space in the blob files, and thus space in the backend filesystem has been reclaimed.
$ ls -ls --block-size 1 /var/lib/storageos/data/dev1/vol.211585.*.blob | awk '!/^total/ {total = total + $1}END{print total}'
469700608
```

### Automating periodic discard

Discard can be automated by running `fstrim` against mounted Ondat volumes.
When running in Kubernetes the Kubelet is responsible for mounting volumes into
pods so the mount endpoints for pods are accessible under
`/var/lib/kubelet/pods`. Ondat volume mounts appear as mounts from
`/var/lib/storageos/volumes/v.${DEPLOYMENT_ID}` on
`/var/lib/kubelet/pods/${POD_UID}/volumes/kubernetes.io~csi/${PV_ID}/mount`.

```
root@unmap:/# mount | awk '/storageos\/volumes\/v.*/'
/var/lib/storageos/volumes/v.4364e143-865e-45d7-a4a5-e0d964d9e200 on /var/lib/kubelet/pods/29ec4774-71d6-4ba3-b275-f80b47e9f6af/volumes/kubernetes.io~csi/pvc-357a9baa-7b74-49db-8d63-c540b5129ad8/mount type ext4 (rw,relatime,stripe=32)
/var/lib/storageos/volumes/v.8dc449a4-1fb5-43d8-86d0-e18916a85c18 on /var/lib/kubelet/pods/6bb92a8f-afb5-48c8-837c-56f45e15e5c4/volumes/kubernetes.io~csi/pvc-2d30a2ba-2663-4036-bb1e-e795f226d6f3/mount type ext4 (rw,relatime,stripe=32)

root@unmap:/# mount | awk '/storageos\/volumes\/v.*/ {print $3}'
/var/lib/kubelet/pods/29ec4774-71d6-4ba3-b275-f80b47e9f6af/volumes/kubernetes.io~csi/pvc-357a9baa-7b74-49db-8d63-c540b5129ad8/mount
/var/lib/kubelet/pods/6bb92a8f-afb5-48c8-837c-56f45e15e5c4/volumes/kubernetes.io~csi/pvc-2d30a2ba-2663-4036-bb1e-e795f226d6f3/mount
```

With this information in mind it is therefore possible to use Kubernetes tools
to automate periodic discard. The `SYS_ADMIN` capability is required to run
`fstrim` and propagation of mounts from the host to the container will allow
any new Ondat mounts to be picked up by the unmap pod.

The naïve example below shows how a pod could be used to run fstrim against
Ondat volumes mounted on the same node that the pod is scheduled on.

```
apiVersion: v1
kind: Pod
metadata:
  name: discard
spec:
  containers:
    - name: fstrim
/docs.
      command: ["/bin/bash"]
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
```

Alternatively a cronjob on the node itself could be used to `fstrim` mounted
Ondat volumes using similar logic.

> ⚠️ TRIM can be an I/O intensive operation so care should be taken when
> running `fstrim` against multiple volumes at once.

## Continuous discard

Ondat volumes can be mounted using the `discard` option which will
automatically send TRIM commands when blocks are removed. Caution should be
used enabling this option as testing has shown that volumes with a lot of churn
can experience performance degradation. The pathological case being a volume
that is continuously filled with small files that are then all deleted,
repeatedly. The [RHEL documentation also recommends doing perodic
discards](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_file_systems/discarding-unused-blocks_managing-file-systems#types-of-block-discard-operations_discarding-unused-blocks).

The discard option can be enabled as a StorageClass or PersistentVolume option.
Enabling `discard` as a StorageClass option will result in all volumes
provisioned with that StorageClass being mounted with `discard` whereas setting
it as a PersistentVolume option sets it on a per volume basis.

The StorageClass below would provision xfs volumes with the `discard` option
enabled by default.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: storageos-discard
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
/docs.
  csi.storage.k8s.io/fstype: xfs
mountOptions:
  - discard
```

You can also edit an existing PersistentVolume to add `discard` to
`.spec.mountOptions`, this ensures that the next time the volume is mounted it
will use `-o discard`.
```yaml
apiVersion: v1
kind: PersistentVolume
/docs.
spec:
/docs.
  mountOptions:
  - discard
  volumeMode: Filesystem
```


