---
title: "Solution - Troubleshooting 'unregistered licence period has expired' Error Message"
linkTitle: "Solution - Troubleshooting 'unregistered licence period has expired' Error Message"
---

## Issue

You are experiencing an issue where a new `PersistentVolumeClaim` (PVC) can’t be provisioned and stays in a `Pending` state.

```bash
# Get the status of PVCs.
kubectl get pvc

NAME       STATUS    VOLUME  CAPACITY   ACCESS MODES   STORAGECLASS            AGE
my-pvc     Pending                                     storageos               2m56s
```

Upon describing the PVC that is in a `Pending` state, under the `Events` section, you see a number of `Warning` events that report  a `unregistered licence period has expired` error message;

```bash
# Describe the PVC named "my-pvc".
kubectl describe pvc my-pvc

Name:          my-pvc
Namespace:     default
StorageClass:  storageos
Status:        Pending
Volume:
Labels:        <none>
Annotations:   storageos.com/encryption-secret-name: storageos-volume-key-7749ab0b-5859-4841-b22a-e06d797dfebb
               storageos.com/encryption-secret-namespace: default
               storageos.com/storageclass: e6bd6278-bc09-43e5-8f5d-c5a59863ab47
               volume.beta.kubernetes.io/storage-provisioner: csi.storageos.com
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type     Reason                Age                From                                                                                          Message
  ----     ------                ----               ----                                                                                          -------
  Warning  ProvisioningFailed    52s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:18:29.841123428 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Warning  ProvisioningFailed    49s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:18:32.000038608 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Warning  ProvisioningFailed    47s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:18:34.713556096 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Warning  ProvisioningFailed    41s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:18:40.23564811 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Warning  ProvisioningFailed    32s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:18:49.096283513 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Normal   Provisioning          16s (x6 over 54s)  csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  External provisioner is provisioning volume for claim "default/pvc-xa"
  Warning  ProvisioningFailed    15s                csi.storageos.com_storageos-csi-helper-65db657d7c-495t9_e8de55aa-5024-4366-a4ce-29ffdf8bd2d6  failed to provision volume with StorageClass "storageos-rep-enc-tap": rpc error: code = Internal desc = internal error: unregistered licence period has expired (expired at 2022-03-09 12:17:35.171452772 +0000 UTC, now 2022-03-15 11:19:06.286764945 +0000 UTC) - see https://docs.storageos.com/v2/help/unlicensed-expired for more information
  Normal   ExternalProvisioning  1s (x5 over 54s)   persistentvolume-controller                                                                   waiting for a volume to be created, either by external provisioner "csi.storageos.com" or manually created by system administrator
```

## Resolution

- Ensure that you apply a valid Ondat licence to your cluster to be able to continue provisioning volumes with Ondat. You can find more information on how to get an Ondat licence on the [Licensing](https://docs.ondat.io/docs/operations/licensing/) operations page.

## Root Cause

- The `error` message that is returned is due to an Ondat licence expiring or an Ondat cluster that has not been registered yet.
	- For more information on the types of licences available, review the [Ondat features and pricing](https://www.ondat.io/pricing) page.
