---
title: "Solution - Troubleshooting 'OutOfRange desc = unsupported capacity size' Error When Provisioning Volumes"
linkTitle: "Solution - Troubleshooting 'OutOfRange desc = unsupported capacity size' Error When Provisioning Volumes"
---

## Issue

After deploying a stateful application into an Ondat cluster, you experience an issue where provisioning Ondat volume for the stateful application is stuck in a `Pending` state.

- Upon further investigation into the persistent volume claims, the `Events:` section reports an `failed to provision volume with StorageClass "storageos": rpc error: code = OutOfRange desc = unsupported capacity size: 1000000000` error message.

```yaml
# Describe the persistent volume claims in a "Pending" state to get more information about the issue.
$ kubectl describe pvc --namespace pgo

Name:          cluster1
Namespace:     pgo
StorageClass:  storageos
Status:        Pending
Volume:
Labels:        pg-cluster=cluster1
               vendor=crunchydata
Annotations:   storageos.com/storageclass: 81e66e90-9140-47ac-8648-c17bbdb7ab8a
               volume.beta.kubernetes.io/storage-provisioner: csi.storageos.com
               volume.kubernetes.io/storage-provisioner: csi.storageos.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type     Reason                Age                   From                                                                                          Message
  ----     ------                ----                  ----                                                                                          -------
  Normal   Provisioning          4m10s (x10 over 10m)  csi.storageos.com_storageos-csi-helper-6bf49c4bd5-fb4wn_ac8d4cb4-3ac4-4766-9cef-2037af393fef  External provisioner is provisioning volume for claim "pgo/cluster1"
  Warning  ProvisioningFailed    4m8s (x10 over 10m)   csi.storageos.com_storageos-csi-helper-6bf49c4bd5-fb4wn_ac8d4cb4-3ac4-4766-9cef-2037af393fef  failed to provision volume with StorageClass "storageos": rpc error: code = OutOfRange desc = unsupported capacity size: 1000000000
  Normal   ExternalProvisioning  44s (x42 over 10m)    persistentvolume-controller                                                                   waiting for a volume to be created, either by external provisioner "csi.storageos.com" or manually created by system administrator


Name:          cluster1-pgbr-repo
Namespace:     pgo
StorageClass:  storageos
Status:        Pending
Volume:
Labels:        pg-cluster=cluster1
               vendor=crunchydata
Annotations:   storageos.com/storageclass: 81e66e90-9140-47ac-8648-c17bbdb7ab8a
               volume.beta.kubernetes.io/storage-provisioner: csi.storageos.com
               volume.kubernetes.io/storage-provisioner: csi.storageos.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       cluster1-backrest-shared-repo-77b9566957-f8jfv
Events:
  Type     Reason                Age                   From                                                                                          Message
  ----     ------                ----                  ----                                                                                          -------
  Normal   Provisioning          4m10s (x10 over 10m)  csi.storageos.com_storageos-csi-helper-6bf49c4bd5-fb4wn_ac8d4cb4-3ac4-4766-9cef-2037af393fef  External provisioner is provisioning volume for claim "pgo/cluster1-pgbr-repo"
  Warning  ProvisioningFailed    4m9s (x10 over 10m)   csi.storageos.com_storageos-csi-helper-6bf49c4bd5-fb4wn_ac8d4cb4-3ac4-4766-9cef-2037af393fef  failed to provision volume with StorageClass "storageos": rpc error: code = OutOfRange desc = unsupported capacity size: 1000000000
  Normal   ExternalProvisioning  29s (x42 over 10m)    persistentvolume-controller                                                                   waiting for a volume to be created, either by external provisioner "csi.storageos.com" or manually created by system administrator
```

## Root Cause

The cause of this error message is due to the usage of [powers of 10](https://en.wikipedia.org/wiki/Power_of_10) storage size units >> (ie, `E, P, T, G, M, k` ) defined in your stateful application manifests instead of using [powers of 2](https://en.wikipedia.org/wiki/Power_of_two) storage size units >> (ie, `Ei, Pi, Ti, Gi, Mi, Ki`).

- `1` _kilobyte_ (symbol `kB`) == `1,000` bytes, whereas
- `1` _kibibyte_ (symbol `KiB`) == `1,024` bytes.

From the [`vmstat`](https://man7.org/linux/man-pages/man8/vmstat.8.html) man page;

> All linux blocks are currently 1024 bytes.  Old kernels may report blocks as 512 bytes, 2048 bytes, or 4096 bytes.
> Since procps 3.1.9, vmstat lets you choose units (k, K, m, M).
> Default is K (1024 bytes) in the default mode.

Ondat conforms to using the default kernel block size -- `1024` bytes as compared to `1000` bytes.

## Resolution

To resolve this issue, end users can either;

- **Option 1 - Upgrade Ondat to release `v2.8.0` or greater**.
  - If users would like to continue to use powers of 10 storage sizing units, ensure that you Ondat cluster is on version `v2.8.0` or greater.
- **Option 2 - Change you manifests to use powers of 2  storage sizing units**.
  - Users can modify their manifests to use `Ei, Pi, Ti, Gi, Mi, Ki` storage sizing units to allow for volumes to be successfully provisioned.

## References

1. [Byte, Multiple-byte Units - Wikipedia](https://en.wikipedia.org/wiki/Byte#Multiple-byte_units)
1. [Resource Units In Kubernetes - Kubernetes Documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
1. [Kubernetes API, Common Definitions, Quantity - Kubernetes Documentation](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/)
