---
title: "How To Use Ondat Files (ReadWriteMany - RWX Volumes)"
linkTitle: "How To Use Ondat Files (ReadWriteMany - RWX Volumes)"
---

## Overview

Ondat support [`ReadWriteMany`](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) (RWX) persistent volumes. A RWX volume can be used simultaneously by different deployments conducting read and write operations in the same namespace.

> ⚠️ RWX volume provisioning is available in the free Ondat Community Edition. To get the Community Edition licence, register your cluster through the [Ondat SaaS platform](https://portal.ondat.io/) and generate a licence so that it can be applied to your cluster. For more information on licences, review the [Ondat pricing](https://www.ondat.io/pricing) page.

> 💡 For more information on the Ondat Files feature, review the  [Ondat Files](https://github.com/ondat/documentation/blob/main/docs/concepts/encryption)  feature page.

### Example - Use the RWX Access Mode Through a `PersistentVolumeClaim` Definition

The following guidance will demonstrate how to use RWX volumes through a  `PersistentVolumeClaim`  (PVC) definition.

- The instructions will allow you to use the RWX access mode on a PVC that will be mounted onto a  `Deployment`  resource in the  `ondat-files`  namespace.

1. Create a namespace called `ondat-files` where the encrypted volume and  `Deployment`  will reside.

 ```bash
 # Create namespace called "ondat-files".
 cat <<EOF | kubectl create --filename -
 apiVersion: v1
 kind: Namespace
 metadata:
   name: ondat-files
   labels:
     name: ondat-files
 EOF
 ```

1. Create a custom `PersistentVolumeClaim` named `ondat-files` and ensure that you add the following `accessMode` >> `ReadWriteMany` to the manifest.

 ```yaml
 # Create a "ondat-files" PVC.
 cat <<EOF | kubectl create --filename -
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   name: ondat-files
   namespace: ondat-files
 spec:
   storageClassName: storageos                # Use the default Ondat StorageClass to provision persistent volumes.
   accessModes:
     - ReadWriteMany                          # Ensure that the access mode is "ReadWriteMany".
   resources:
     requests:
       storage: 5Gi
 EOF
 ```

1. Once the PVC resource has been successfully created, review and confirm that the `ReadWriteMany` access mode has been applied.

 ```bash
 # Get the label applied to the "ondat-files" PVC.
 kubectl get pvc ondat-files --output=wide --show-labels --namespace=ondat-files
 ```

1. Create a `Deployment` workload in the `ondat-files` namespace that uses the `ondat-files` PVC that was created in *Step 2*.

 ```yaml
 cat <<EOF | kubectl create --filename -
 apiVersion: apps/v1
 kind: Deployment
 metadata:
   labels:
     app: ondat-files
   name: ondat-files-deployment-rwx
   namespace: ondat-files                             # Create the Deployment workload in the "ondat-files" namespace.
 spec:
   replicas: 3
   selector:
     matchLabels:
       app: ondat-files
   template:
     metadata:
       labels:
         app: ondat-files
     spec:
       containers:
       - args:
         - "3600"
         command:
         - /bin/sleep
         image: debian:latest
         name: debian
         volumeMounts:
         - mountPath: /mnt/
           name: ondat-files
       volumes:
       - name: ondat-files
         persistentVolumeClaim:
           claimName: ondat-files                    # Use the "ondat-files" PVC for the StatefulSet workload.
 EOF
 ```

1. To review and confirm that the `ondat-files-deployment-rwx` Kubernetes deployment has successfully mounted the RWX volume, run the following commands below to inspect the resources created.

 ```bash
 # Review and confirm that Deployment workload was successfully created.
 kubectl get pod --namespace=ondat-files
 kubectl get deployments.apps --namespace=ondat-files
 ```

1. When you review the [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/) in the `ondat-files` namespace, you will notice that there is an [NFS Ganesha](https://github.com/nfs-ganesha/nfs-ganesha) service that exposes the PVC as a shared filesystem - in addition, provides the `ClusterIP` address of the service and the default NFS port of >> `2049/TCP`.

 ```bash
 # Check the service created under the "ondat-files" namespace.
 kubectl get service --namespace ondat-files

 NAME                                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
 pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae   ClusterIP   10.0.133.137   <none>        2049/TCP   6m46s
 ```

 ```yaml
 # Describe the service in the namespace.
 kubectl describe service --namespace ondat-files

 Name:              pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae
 Namespace:         ondat-files
 Labels:            storageos.com/volume-id=aad1e4ab-23d2-4a45-9a9b-0305885997ff
 Annotations:       <none>
 Selector:          <none>
 Type:              ClusterIP
 IP Family Policy:  SingleStack
 IP Families:       IPv4
 IP:                10.0.133.137
 IPs:               10.0.133.137
 Port:              nfs  2049/TCP
 TargetPort:        25918/TCP
 Endpoints:         10.224.0.4:25918
 Session Affinity:  None
 Events:
   Type    Reason   Age    From                   Message
   ----    ------   ----   ----                   -------
   Normal  Created  9m35s  storageos-api-manager  Created service for shared volume ondat-files/pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae
 ```

1. You can also review and confirm that Ondat has successfully provisioned a RWX volume, as defined in the PVC manifest earlier, by running the [Ondat CLI utility as a deployment](/docs/reference/cli/) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

 ```bash
 # Get the pod name of the Ondat CLI utility.

 kubectl get pods --namespace storageos | grep "storageos-cli"
 storageos-cli-578c4f4674-wr9z2                       1/1     Running   0              3m43s
 ```

 ```bash
 # Get the volumes in the "ondat-files" namespace using the Ondat CLI.
 kubectl --namespace=storageos exec storageos-cli-578c4f4674-wr9z2 -- storageos get volumes --namespace=ondat-files

 NAMESPACE    NAME                                      SIZE     LOCATION                                  ATTACHED ON                      REPLICAS  AGE
 ondat-files  pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae  5.0 GiB  aks-default-15645363-vmss000000 (online)  aks-default-15645363-vmss000000  0/0       2 hours ago

 # Describe the "pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a" volume.
 kubectl --namespace=storageos exec storageos-cli-578c4f4674-wr9z2 -- storageos describe volume pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae --namespace=ondat-files

 ID                      aad1e4ab-23d2-4a45-9a9b-0305885997ff
 Name                    pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae
 Description
 AttachedOn              aks-default-15645363-vmss000000 (1c9fe8f8-7c33-44b0-802d-875ff4c53fdd)
 Attachment Type         nfs
 NFS
   Service Endpoint      10.224.0.4:25918
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
 Namespace               ondat-files (97e1ffeb-34e3-4f18-8ef1-5494f34fe9cd)
 Labels                  csi.storage.k8s.io/pv/name=pvc-41f429ff-3fa9-4361-b7bc-c55f869499ae,
                         csi.storage.k8s.io/pvc/name=ondat-files,
                         csi.storage.k8s.io/pvc/namespace=ondat-files,
                         storageos.com/nfs/mount-endpoint=10.0.133.137:2049,
                         storageos.com/nocompress=true
 Filesystem              ext4
 Size                    5.0 GiB (5368709120 bytes)
 Version                 NQ
 Created at              2022-09-08T12:54:49Z (2 hours ago)
 Updated at              2022-09-08T14:29:18Z (28 minutes ago)

 Master:
   ID                    67cae629-7797-444a-828d-22d5c22d3535
   Node                  aks-default-15645363-vmss000000 (1c9fe8f8-7c33-44b0-802d-875ff4c53fdd)
   Health                online
 ```

1. Notice under `Attachment Type         nfs`, the detailed information about the RWX volume is returned.

 ```yaml
 # truncated output..
 Attachment Type         nfs
 NFS
   Service Endpoint      10.224.0.4:25918
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
 # truncated ouput...
 ```

## NFS Squash Mode

> 💡 This feature is available in release  `v2.8.0`  or greater.

As part of the `v2.8.0` Ondat release, a change was made so that users can [configure the squash mode](https://linux.die.net/man/5/exports) for the NFS service that is used to provision RWX shares.

- Historically, all shares were exported with a `Squash = All`  mode of operation. This was requested by most customers as the idea of identity in a container based deployment is very abstract.
- There is now a Ondat volume [Feature label](/docs/concepts/labels/) that can be applied to make this setting configurable. End users can now adjust the squash mode using the following label >> `storageos.com/nfs-squash: $APPLY_SQUASH_MODE_VALUE` when provisioning RWX volumes. Below are the list of different modes that users can apply (`all` is the default mode and the label is applied to a `PersistentVolumeClaim`)

| Squash Mode - Options |
| --------------------- |
| `all` (default)       |
| `root`                |
| `rootuid`             |
| `none`                |

### Example - Configure the Squash Mode for a RWX Volume Through a `PersistentVolumeClaim` Definition

The following guidance will demonstrate how to configure the squash mode for a RWX volume through a `PersistentVolumeClaim` (PVC) definition.

- The instructions will allow you to use the RWX access mode on a PVC which has the squash mode set to `rootuid` that will be mounted onto a `Deployment` resource in the `ondat-files-squash-mode` namespace.

1. Create a namespace called `ondat-files-squash-mode` where the encrypted volume and `Deployment` will reside.

 ```bash
 # Create namespace called "ondat-files-squash-mode".
 cat <<EOF | kubectl create --filename -
 apiVersion: v1
 kind: Namespace
 metadata:
   name: ondat-files-squash-mode
   labels:
     name: ondat-files-squash-mode
 EOF
 ```

1. Create a custom `PersistentVolumeClaim` named `ondat-files-squash-mode`, ensure that the label is set `storageos.com/nfs-squash: rootuid` and ensure that you add the following `accessMode` >> `ReadWriteMany`  added to the manifest.

 ```yaml
 # Create a "ondat-files-squash-mode" PVC.
 cat <<EOF | kubectl create --filename -
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   name: ondat-files-squash-mode
   namespace: ondat-files-squash-mode
   labels:
     storageos.com/nfs-squash: rootuid        # set the squash mode to "rootuid".
 spec:
   storageClassName: storageos                # Use the default Ondat StorageClass to provision persistent volumes.
   accessModes:
     - ReadWriteMany                          # Ensure that the access mode is "ReadWriteMany".
   resources:
     requests:
       storage: 5Gi
 EOF
 ```

1. Once the PVC resource has been successfully created, review and confirm that the `storageos.com/nfs-squash: rootuid` label has been applied.

 ```bash
 # Get the label applied to the "ondat-files-squash-mode" PVC.
 kubectl get pvc ondat-files-squash-mode --output=wide --show-labels --namespace=ondat-files-squash-mode
 ```

1. Create a `Deployment` workload in the `ondat-files-squash-mode` namespace that uses the `ondat-files-squash-mode` PVC that was created in *Step 2*.

 ```yaml
 cat <<EOF | kubectl create --filename -
 apiVersion: apps/v1
 kind: Deployment
 metadata:
   labels:
     app: ondat-files-squash-mode
   name: ondat-files-deployment-rwx-squash-mode
   namespace: ondat-files-squash-mode               # Create the Deployment workload in the "ondat-files-squash-mode" namespace.
 spec:
   replicas: 3
   selector:
     matchLabels:
       app: ondat-files-squash-mode
   template:
     metadata:
       labels:
         app: ondat-files-squash-mode
     spec:
       containers:
       - args:
         - "3600"
         command:
         - /bin/sleep
         image: debian:latest
         name: debian
         volumeMounts:
         - mountPath: /mnt/
           name: ondat-files-squash-mode
       volumes:
       - name: ondat-files-squash-mode
         persistentVolumeClaim:
           claimName: ondat-files-squash-mode        # Use the "ondat-files-squash-mode" PVC for the StatefulSet workload.
 EOF
 ```

1. To review and confirm that the `oondat-files-deployment-rwx-squash-mode` Kubernetes deployment has successfully mounted the RWX volume, run the following commands below to inspect the resources created.

 ```bash
 # Review and confirm that Deployment workload was successfully created.
 kubectl get pod --namespace=ondat-files-squash-mode
 kubectl get deployments.apps --namespace=ondat-files-squash-mode
 ```

1. When you review the [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/) in the `ondat-files-squash-mode` namespace, you will notice that there is an [NFS Ganesha](https://github.com/nfs-ganesha/nfs-ganesha) service that exposes the PVC as a shared filesystem - in addition, provides the `clusterIP` address of the service and the default NFS port of >> `2049/TCP`.

 ```bash
 # Check the service created under the "ondat-files-squash-mode" namespace.
 kubectl get service --namespace ondat-files-squash-mode
 
    NAME                                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342   ClusterIP   10.0.159.162   <none>        2049/TCP   28s
 ```

 ```yaml
 # Describe the service in the namespace.
 kubectl describe service --namespace ondat-files-squash-mode

 Name:              pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342
 Namespace:         ondat-files-squash-mode
 Labels:            storageos.com/volume-id=17450a4e-ecf6-4e98-918f-19e748bf9737
 Annotations:       <none>
 Selector:          <none>
 Type:              ClusterIP
 IP Family Policy:  SingleStack
 IP Families:       IPv4
 IP:                10.0.159.162
 IPs:               10.0.159.162
 Port:              nfs  2049/TCP
 TargetPort:        25805/TCP
 Endpoints:         10.224.0.8:25805
 Session Affinity:  None
 Events:
   Type    Reason   Age    From                   Message
   ----    ------   ----   ----                   -------
   Normal  Created  4m47s  storageos-api-manager  Created service for shared volume ondat-files-squash-mode/pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342
 ```

1. You can also review and confirm that Ondat has successfully provisioned a RWX volume, as defined in the PVC manifest earlier, by running the [Ondat CLI utility as a deployment](/docs/reference/cli/) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

 ```bash
 # Get the pod name of the Ondat CLI utility.

 kubectl get pods --namespace storageos | grep "storageos-cli"
 storageos-cli-578c4f4674-wr9z2                       1/1     Running   0              3m43s
 ```

 ```bash
 # Get the volumes in the "ondat-files-squash-mode" namespace using the Ondat CLI.
 kubectl --namespace=storageos exec storageos-cli-578c4f4674-wr9z2 -- storageos get volumes --namespace=ondat-files-squash-mode

 NAMESPACE                NAME                                      SIZE     LOCATION                                  ATTACHED ON                      REPLICAS  AGE
 ondat-files-squash-mode  pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342  5.0 GiB  aks-storage-32661963-vmss000001 (online)  aks-storage-32661963-vmss000001  0/0       15 minutes ago

 # Describe the "pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342" volume.
 kubectl --namespace=storageos exec storageos-cli-578c4f4674-wr9z2 -- storageos describe volume pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342 --namespace=ondat-files-squash-mode

 ID                      17450a4e-ecf6-4e98-918f-19e748bf9737
 Name                    pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342
 Description
 AttachedOn              aks-storage-32661963-vmss000001 (acdf3a74-4042-492d-b7b4-8368f5474fb2)
 Attachment Type         nfs
 NFS
   Service Endpoint      10.224.0.8:25805
   Exports:
   - ID                  1
     Path                /
     Pseudo Path         /
     ACLs
     - Identity Type     hostname
       Identity Matcher  *
       Squash            rootuid
       Squash UID        0
       Squash GUID       0
 Namespace               ondat-files-squash-mode (39d924f6-2d16-48e6-af1a-a69169f4bd6b)
 Labels                  csi.storage.k8s.io/pv/name=pvc-bd4c93a5-0071-4a56-968c-ae5e12d34342,
                         csi.storage.k8s.io/pvc/name=ondat-files-squash-mode,
                         csi.storage.k8s.io/pvc/namespace=ondat-files-squash-mode,
                         storageos.com/nfs-squash=rootuid,
                         storageos.com/nfs/mount-endpoint=10.0.159.162:2049,
                         storageos.com/nocompress=true
 Filesystem              ext4
 Size                    5.0 GiB (5368709120 bytes)
 Version                 NQ
 Created at              2022-09-08T17:07:35Z (17 minutes ago)
 Updated at              2022-09-08T17:15:36Z (8 minutes ago)

 Master:
   ID                    662ac10a-b695-4c5f-ba4e-2b003b098dfc
   Node                  aks-storage-32661963-vmss000001 (acdf3a74-4042-492d-b7b4-8368f5474fb2)
   Health                online
 ```

1. If you notice under `Attachment Type         nfs`, detailed information about the RWX volume is returned.

 ```yaml
 Attachment Type         nfs
 NFS
   Service Endpoint      10.224.0.8:25805
   Exports:
   - ID                  1
     Path                /
     Pseudo Path         /
     ACLs
     - Identity Type     hostname
       Identity Matcher  *
       Squash            rootuid
       Squash UID        0
       Squash GUID       0
 ```
