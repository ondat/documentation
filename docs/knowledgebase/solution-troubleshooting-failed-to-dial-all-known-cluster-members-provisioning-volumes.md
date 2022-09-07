---
title: "Solution - Troubleshooting 'failed to dial all known cluster members' Error When Provisioning Volumes"
linkTitle: "Solution - Troubleshooting 'failed to dial all known cluster members' Error When Provisioning Volumes"
---

## Issue

- You are experiencing a `ProvisioningFailed` event error message when you try to create a `PersistentVolumeClaim` (PVC) and it remains in a `Pending` state, thus preventing the pods that needs to mount that PVC from successfully starting up. Below is an example of the error message that shows up in the `Events:` log of the PVC.

```bash
# Get the status of the PVC.
kubectl get pvc vol-1 --namespace example-namespace

NAME      STATUS        VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
vol-1     Pending                                                                            storageos       7s

# Describe the PVC that is stuck in a Pending state.
kubectl describe pvc vol-1 --namespace example-namespace

# truncated output.
Events:
  Type     Reason              Age               From                         Message
  ----     ------              ----              ----                         -------
  Warning  ProvisioningFailed  7s (x2 over 18s)  persistentvolume-controller  Failed to provision volume with StorageClass "storageos": Get http://storageos-cluster/version: failed to dial all known cluster members, (10.233.59.206:5705)
``` 

## Root Cause

For non Container Storage Interface (CSI) installations of Ondat, Kubernetes uses the Ondat API endpoint to communicate. If that communication fails, relevant actions such as create or mount volume can’t be transmitted to Ondat, hence the PVC will remain in `Pending` state. Ondat never received the action to perform, so it never sent back an acknowledgement.
- In this case, the `Events:` message indicates that Ondat API is not responding, implying that Ondat is not running. For Kubernetes to confirm that Ondat pods are `READY`, health checks must be passed first.

## Resolution

- Check and ensure that Ondat pods deployed in the cluster are `READY`, ie `1/1` instead of `0/1`:

```bash
# check the status of Ondat pods.
kubectl --namespace storageos get pods --selector app=storageos

NAME                   READY     STATUS    RESTARTS   AGE
storageos-node-qrqkj   0/1       Running   0          1m
storageos-node-s4bfv   0/1       Running   0          1m
storageos-node-vcpfx   0/1       Running   0          1m
storageos-node-w98f5   0/1       Running   0          1m
```

- If the Ondat pods are not `READY`, the service will not forward traffic to the API they serve thus, the PVC will remain in `Pending` state until Ondat pods are available.

> 💡 Kubernetes will keep trying to ensure that startup containers successfully. If a PVC is created before Ondat finish starting, the PVC will be created eventually once the Ondat pods are running.

- Ondat's health check gives  `60` seconds of grace period before reporting as `READY`. If Ondat successfully startups after that period, the volume will be created when Ondat finishes its bootstrap.
- If Ondat pods are still not in a `READY` state after waiting for some time, a recommendation would be to investigate further into the Ondat deployment and ensure that there is no mis-configuration issue.
