---
title: "Solution - Unable To Mount RWX Volumes To A Pod"
linkTitle: "Solution - Unable To Mount RWX Volumes To A Pod"
---

## Issue

A `PersistentVolumeClaim` (PVC) is bound and the Ondat volume appears to be in a healthy state, but the volume was never mounted to the assigned pod.
- Below is the error message that is returned in the `Events` section when you describe the pod.

```bash
# describe the "my-pod-mounting-rwx-volume" pod.
kubectl describe pod my-pod-mounting-rwx-volume

# truncated output.
Events:
  Type     Reason       Age                  From                 Message
  ----     ------       ----                 ----                 -------
  Normal   Scheduled    7m39s                storageos-scheduler  Successfully assigned default/test4-849f875f74-dmjtr to ip-10-73-16-8.eu-west-2.compute.internal
  Warning  FailedMount  94s                  kubelet              MountVolume.SetUp failed for volume "pvc-c30e3215-bbd6-4dd5-a6e2-84de1fb06097" : rpc error: code = DeadlineExceeded desc = context deadline exceeded
  Warning  FailedMount  63s (x3 over 5m36s)  kubelet              Unable to attach or mount volumes: unmounted volumes=[v1], unattached volumes=[v1 kube-api-access-h9njv]: timed out waiting for the condition
```

## Resolution

- Check and ensure that there is a [service](https://kubernetes.io/docs/concepts/services-networking/service/) for the RWX volume in the same namespace where the pod is located. If the service does not exist, a recommendation would be to follow the instructions below.

```bash
# Define environment variables.
PVC_NAME="my-volume-name"
PV_NAME=$(kubectl get pvc $PVC_NAME -ojsonpath='{.spec.volumeName}'))

# Get the PersistentVolume (PV) name associated to your PersistentVolumeClaim (PVC).
kubectl get service | grep $PV_NAME
```

- You can also use the [Ondat CLI](/docs/reference/cli/) to also check the health status of the volume. Notice that there is no assigned port under the `Service Endpoint:` key-value pair as demonstrated below;

```bash
# Use the Ondat CLI to describe the RWX volume which does not have a service.
storageos describe volume $PV_NAME

ID                      a3802f33-93f5-4b1e-9253-5430c7abc71e
Name                    pvc-5a7abc65-a0b7-4397-b782-1597c9e1ab8d
Description
AttachedOn              
Attachment Type         nfs
NFS
  Service Endpoint:    
  Exports:
  - ID                  1
    Path                /
    Pseudo Path         /
    ACLs
    - Identity Type     hostname
      Identity Matcher  *
      Squash            all
      Squash UID        0
      Squash GUID       0
Namespace               default (e4344675-311b-453c-8a59-71ef5b2e98cf)
Labels                  csi.storage.k8s.io/pv/name=pvc-5a7abc65-a0b7-4397-b782-1597c9e1ab8d,
                        csi.storage.k8s.io/pvc/name=pvc-rwx2,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/nocompress=true
Filesystem              ext4
Size                    5.0 GiB (5368709120 bytes)
Version                 NQ
Created at              2022-02-10T16:55:12Z (7 minutes ago)
Updated at              2022-02-10T16:55:34Z (6 minutes ago)

Master:
  ID                    4c5a91a5-f7cd-4d2c-a63e-fc23049b4321
  Node                  ip-10-73-17-108.eu-west-2.compute.internal (26d7a07c-1d68-49e9-a541-d0eb93ab77b9)
  Health                online
```

- Check and ensure that the ports in the range of `25705-25960` is accessible between the worker nodes in your Kubernetes cluster. You can find more information on the ports required for RWX Volume Endpoints in the [Firewall](/docs/prerequisites/firewalls/) prerequisites page.
 
## Root Cause

- The error message is related to the fact that there is no `Service Endpoint:` for the RWX NFS server.
  - The Ondat Control Plane in the `storageos-node-xxxx` daemonset pod spawns a Ganesha NFS server that is bound to the host network on a port in the range [`25705-25960`](/docs/prerequisites/firewalls/). If the Pod cannot bound to the port for the Ganesha the `Service Endpoint:` value will show as empty.
