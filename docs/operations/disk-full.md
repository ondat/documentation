---
title: "Disk Full"
linkTitle: Disk Full
---

When the physical disks in your cluster get full, or start using disk space too
fast, Kubernetes will automatically apply the `DiskPressure:NoExecute` taint.

The Ondat Daemonset has a toleration applied for this taint, so it will
continue to run.

## Detecting a full disk

You will see the following when viewing the Ondat container logs on the
affected node with `kubectl logs storageos-daemonset-xxxx -c storageos`:

``` text
"msg": "StartAsyncFallocate: insufficient free space on file system free_space=1048305664 required_free_space=1073741824",
"msg": "Write: write failed volid=155051 error=BlobStorage::PrepWrite encountered a previous IO error preventing future IO for safety",
"msg": "Write: write failed volid=155051 error=all blob files are full - can not complete write",
"msg": "Write: write failed volid=155051 error=BlobStorage::PrepWrite encountered a previous IO error preventing future IO for safety",
"msg": "SCSI command failed type=write error=FATAL retries=0 time_to_deadline_secs=89",
```

When trying to attach a volume to a node with a full disk you will see the
following when running `kubectl describe pod $POD_USING_VOLUME`:

``` text
AttachVolume.Attach failed for volume "pvc-xxx" : rpc error: code = Internal desc = internal error: rpc error: code = Internal desc = rpc error: code = Internal desc = fs: STATUS_FORBIDDEN: create failed in Notify handler error=Failed to create LUN for FsConfigVolume{volume_id=
```

## Consequences of a full disk

### Volume Provisioning

When provisioning a new volume, the dataplane checks that there is at least
`1GB` of space left on the nodes' underlying filesystem for the blob files
located at `/var/lib/storageos/data/dev[0-9]+/vol.xxxxxx.0.blob` and
`/var/lib/storageos/data/dev[0-9]+/vol.xxxxxx.1.blob`.

If there is insufficient space for both of the blob files that Ondat uses
to store data, then the dataplane fails the volume `create` request.

### Runtime Access

At runtime, if an attempted write to a blob file returns an `ENOSPC` exception,
the dataplane marks the file as full. Once both Ondat blob files in a
volume are marked as full, the dataplane marks the deployment with an error
flag, and all subsequent read/write operations will return an I/O error.

*This flag is only stored in memory, therefore, to clear this flag, the
Ondat daemonset pod on the affected node must be restarted after
remediating the disk space issue.*

### Replica Failover

A replica on a full disk can't be failed over successfully.

## Recovering from a full disk

To recover from a disk full error, you can either add new storage space
into the affected node, or delete existing persistent volume claims.

>**N.B.** However you choose to resolve the issue, the **Ondat Daemonset
>Pod must be restarted**.

This is because the blob files disallow operations at runtime via the
previously discussed error flag stored in memory. This flag does not survive
boot cycles, so after the pod restarts, volumes can operate normally once more.

### Adding New Storage Space

If you choose to recover by expanding your capacity, you have two main options:

1. Add new storage devices at `/var/lib/storageos/data/dev[0-9]+` as described
   [here](/docs/operations/managing-host-storage#option-1-mount-additional-devices).
2. Expand the underlying filesystem that Ondat is using as described
   [here](/docs/operations/managing-host-storage"#option-2-expand-existing-devices-backed-by-lvm).

After expanding capacity remember to restart the Ondat daemonset pod.

### Deleting existing PVCs

If you choose to recover by deleting existing persistent volume claims simply:

`kubectl delete pvc <PVCOnFullNodeName>`

Then restart the Ondat daemonset pod.
