---
title: "Solution - Deployment Using A RWX Volume Is Stuck In A 'ContainerCreating' State"
linkTitle: "Solution - Deployment Using A RWX Volume Is Stuck In A 'ContainerCreating' State"
---

## Issue

- You are experiencing an issue where your Kubernetes resource that is using an Ondat RWX volume is stuck in `ContainerCreating` state. Below is example outputs of a deployment experiencing this error message;

```bash
# Get the status of the pods in the "ondat-files" namespace.
kubectl get pod --namespace=ondat-files

NAME                                         READY   STATUS              RESTARTS   AGE
ondat-files-deployment-rwx-d68b4866d-khl2d   0/1     ContainerCreating   0          13m
ondat-files-deployment-rwx-d68b4866d-twzrt   0/1     ContainerCreating   0          13m
ondat-files-deployment-rwx-d68b4866d-z5xhm   0/1     ContainerCreating   0          13m

# Get the status of the deployment, notice that the 0 out 3 pods are READY.
kubectl get deployments.apps --namespace ondat-files

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
ondat-files-deployment-rwx   0/3     3            0           18m
```

- Upon describing one of the replica pods of the deployment to further investigate, you may notice the following error message in the `Events:` section >> `rpc error: code = Internal desc = internal error: the "nfs" licence feature is required to perform the requested operation`.

```bash
# Describe one of the affected replica pods of the deployment
kubectl describe pod ondat-files-deployment-rwx-d68b4866d-twzrt --namespace ondat-files

# truncated output...
Events:
  Type     Reason              Age                 From                     Message
  ----     ------              ----                ----                     -------
  Normal   Scheduled           18m                 storageos-scheduler      Successfully assigned ondat-files/ondat-files-deployment-rwx-d68b4866d-twzrt to aks-default-15645363-vmss000000
  Warning  FailedMount         14m                 kubelet                  Unable to attach or mount volumes: unmounted volumes=[ondat-files], unattached volumes=[kube-api-access-ng2c5 ondat-files]: timed out waiting for the condition
  Warning  FailedMount         67s (x7 over 16m)   kubelet                  Unable to attach or mount volumes: unmounted volumes=[ondat-files], unattached volumes=[ondat-files kube-api-access-ng2c5]: timed out waiting for the condition
  Warning  FailedAttachVolume  22s (x17 over 18m)  attachdetach-controller  AttachVolume.Attach failed for volume "pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae" : rpc error: code = Internal desc = internal error: the "nfs" licence feature is required to perform the requested operation
```

## Root Cause

- In order for end user to be able to successfully provision RWX volumes, an Ondat cluster must be licensed with either a *Community*, *Standard* or *Enterprise* Edition. RWX volume provisioning is available in the free Ondat Community Edition.
  - For more information on licences, review the [Ondat pricing](https://www.ondat.io/pricing) page.

## Resolution

1. To get the Community Edition licence, register your cluster through the [Ondat SaaS platform](https://portal.ondat.io/) and generate a licence so that it can be applied to your cluster.

 > 💡 If you already have an Ondat cluster that is connected to the Ondat SaaS Platform, you can apply the licence automatically to the connected cluster by following the steps below;

1. Login to the  **Ondat SaaS Platform**  »  **Organisation**  »  **Licences**  »  **Generate A New Licence**  »  **Choose an existing cluster**  » Select the cluster that you want to apply a licence to.
1. Once the cluster has been successfully licensed, end users will be able to create resources that use Ondat RWX volumes.
