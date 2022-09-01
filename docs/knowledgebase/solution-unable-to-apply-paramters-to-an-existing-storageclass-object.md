---
title: "Solution - Unable To Apply Parameters To An Existing StorageClass Object"
linkTitle: "Solution - Unable To Apply Parameters To An Existing StorageClass Object"
---

## Issue

You have created a custom `StorageClass` object in your Ondat cluster but you are experiencing an issue where you cannot interactively edit or patch the said `StorageClass` object and apply a custom `StorageClass` parameter to enable specific Ondat [features](/docs/concepts/labels/). 

```bash
# Get the list of StorageClasses available.
kubectl get sc
NAME                          PROVISIONER                 RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
storageos                     csi.storageos.com           Delete          Immediate           true                   3h3m
storageos-rep                 csi.storageos.com           Delete          Immediate           true                   23s
```
Using the example below, try to edit `storageos-rep` and change the replica count to `2`:

```yaml

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"storageos-rep"},"parameters":{"csi.storage.k8s.io/fstype":"ext4","csi.storage.k8s.io/secret-name":"storageos-api","csi.storage.k8s.io/secret-namespace":"storageos","storageos.com/replicas":"1"},"provisioner":"csi.storageos.com"}
  creationTimestamp: "2022-09-01T18:08:46Z"
  name: storageos-rep
  resourceVersion: "68902"
  uid: 74ad669c-885c-466a-b9b8-a8100c10d35e
parameters:
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
  storageos.com/replicas: "2"
provisioner: csi.storageos.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

After attempting to save the changes you made and exiting from the editor, an error message >> `error: storageclasses.storage.k8s.io "storageos-rep" is invalid` is returned as demonstrated below:

```bash
error: storageclasses.storage.k8s.io "storageos-rep" is invalid
A copy of your changes has been stored to "/var/folders/h5/8782r8c93190wt_mmly0ph5r0000gn/T/kubectl-edit-2033723251.yaml"
error: Edit cancelled, no valid changes were saved.
```

## Root Cause

In Kubernetes, a `StorageClass` is an [immutable](https://en.wikipedia.org/wiki/Immutable_object) object once it has been created - therefore it is not possible to patch or add custom parameters to an existing `StorageClass` object.

## Resolution

To resolve this issue, an end user can either;
- **Option 1 - Use [volume labels](/docs/concepts/labels/) to enable Ondat features.**
	- Users can use the existing `StorageClass` object and dynamically create `PersistentVolumeClaim` definitions that enable Ondat features through volume labels:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  labels:
    storageos.com/replicas: "2"
spec:
  storageClassName: "storageos-rep"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
# Create the PVC and get the details of the label applied to the PVC.
kubectl apply -f test-pvc.yaml
kubectl get pvc test-pvc --output wide --show-labels

NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE   LABELS
test-pvc   Bound    pvc-3afbc6ff-09f2-4360-84dc-440193a9fbd9   1Gi        RWO            storageos-rep  2m59s   Filesystem   storageos.com/replicas=2
```

- **Option 2 - Create a new `StorageClass` object with the desired parameters**.

```yaml
# Create a "storageos-rep-2" StorageClass object.
cat <<EOF | kubectl create --filename -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: storageos-rep-2
provisioner: csi.storageos.com
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/secret-name: storageos-api
  csi.storage.k8s.io/secret-namespace: storageos
  storageos.com/replicas: "2"
EOF
```

```yaml
# Describe the "storageos-rep-2" StorageClass object to verify the label's existance.
kubectl describe sc storageos-rep-2

Name:                  storageos-rep-2
IsDefaultClass:        No
Annotations:           <none>
Provisioner:           csi.storageos.com
Parameters:            csi.storage.k8s.io/fstype=ext4,csi.storage.k8s.io/secret-name=storageos-api,csi.storage.k8s.io/secret-namespace=storageos,storageos.com/replicas=2
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

## References

1. [Storage Classes - Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/)
