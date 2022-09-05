---
title: "Solution - Troubleshooting Insufficient Free Space On Storage Disks Attached To Nodes"
linkTitle: "Solution - Troubleshooting Insufficient Free Space On Storage Disks Attached To Nodes"
---

## Issue

- You are noticing the following error messages (demonstrated in the snippet below) in the logs of a Ondat daemonset pod named `storageos-node-xxxx` that is running on a node that is running out of space.

```yaml
# Check the logs of a Ondat daemonset pod.
kubectl logs storageos-node-xxxx --namespace storageos

# Truncated output.
"msg": "StartAsyncFallocate: insufficient free space on file system free_space=1048305664 required_free_space=1073741824",
"msg": "Write: write failed volid=155051 error=BlobStorage::PrepWrite encountered a previous IO error preventing future IO for safety",
"msg": "Write: write failed volid=155051 error=all blob files are full - can not complete write",
"msg": "Write: write failed volid=155051 error=BlobStorage::PrepWrite encountered a previous IO error preventing future IO for safety",
"msg": "SCSI command failed type=write error=FATAL retries=0 time_to_deadline_secs=89",
```

- When you try to attach a volume to a node with a full disk, you see the following event error message after describing the pod using the volume:

```bash
# Describe the pod trying to use the affected volume.
kubectl describe pod $POD_NAME_USING_VOLUME --namespace $POD_NAMESPACE

# Truncated output.
AttachVolume.Attach failed for volume "pvc-xxx" : rpc error: code = Internal desc = internal error: rpc error: code = Internal desc = rpc error: code = Internal desc = fs: STATUS_FORBIDDEN: create failed in Notify handler error=Failed to create LUN for FsConfigVolume{volume_id=
```

## Root Cause

The root cause of the issue due to the physical storage disks connected to your worker nodes in your Ondat cluster becoming full, or they are using disk space too quickly. To reduce the chances of downtime in the cluster, Kubernetes will automatically apply the [`node.kubernetes.io/disk-pressure` taint](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#taint-based-evictions) on affected nodes.
- The Ondat daemonset pods, which have the control and data plane components, has a [toleration](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) applied for this taint, to allow the daemonset to continue to run.

### What Are The Consequences Of A Full Storage Disk?

- **Unable To Conduct Replica Failovers**.
	- If there is a replica on a node where the storage disk has run out of space, the replica will be unable to failover successfully.
- **Unable To Provision Volumes**.
	- When provisioning a new volume, the data plane component will check that there is at least **`1GB`** of storage space left on the nodes' underlying filesystem for the blob files located under >> `/var/lib/storageos/data/dev[0-9]+/vol.xxxxxx.0.blob` and >> `/var/lib/storageos/data/dev[0-9]+/vol.xxxxxx.1.blob`.
	- If there is insufficient storage space for both of the blob files that Ondat uses to store data, then the data plane component will fail to complete the volume `create` request.
- **Runtime Access Issues**.
	- At runtime, if an attempted write to a blob file returns an `ENOSPC` exception, the data plane component marks the file as full.
	- Once both Ondat blob files in a volume are marked as full, the data plane component marks the deployment with an error flag, and all subsequent read/write operations will return an I/O error.

> 💡 This flag is only stored in memory, therefore, to clear this flag, the Ondat daemonset pod on the affected node must be restarted after remediating the disk space issue.


## Resolution

To recover from a reported full disk error message, end users are recommended to either:
1. **Option 1 - Expand Storage Capacity By Adding More Disks**.
	- If you choose to address this issue by expanding your capacity, users have two main options:
		- Add new storage devices under `/var/lib/storageos/data/dev[0-9]+` as demonstrated in the [How To Extend Storage Capacity On Nodes](https://docs.ondat.io/docs/operations/managing-host-storage/) operations page.
		- Expand the underlying filesystem that Ondat is using as demonstrated in the [How To Extend Storage Capacity On Nodes](https://docs.ondat.io/docs/operations/managing-host-storage/) operations page.
1. **Option 2 - Delete Existing `PersistentVolumeClaim`s (PVCs)**
	- If you choose to address by deleting existing `PersistentVolumeClaim`s, users can use `kubectl` to achieve this and ensure that you restart/bounce the Ondat daemonset pod on the affected node.

```bash
kubectl delete pvc $NAME_OF_PVC --namespace $PVC_NAMESPACE
```

> ⚠️ Regardless of the solution used to address this issue - it is important that the **Ondat Daemonset Pod restarted** for changes to be applied and take effect. The reason for this is because blob files disallow operations at runtime through the previously discussed `ENOSPC` error flag stored in memory. This flag does not survive boot cycles, so after the the daemonset pod restarts, volumes can begin to successfully operate again.
