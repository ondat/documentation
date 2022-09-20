---
title: "Solution - Troubleshooting 'failed to get secret from' Error When Provisioning Volumes"
linkTitle: "Solution - Troubleshooting 'failed to get secret from' Error When Provisioning Volumes"
---

## Issue

- You are experiencing an issue where a `PersistentVolumeClaim` (PVC) that has been created, continues to remain in a `Pending` state - thus preventing pods from successfully starting up as they require the said PVC to mount first. Below is an example output of the error message from the `Events:` section of an affected PVC;

```bash
# Describe the PVC that is stuck in a Pending state.
kubectl describe pvc vol-1 --namespace example-namespace

# Truncated output.
Events:
  Type     Reason              Age                From                         Message
  ----     ------              ----               ----                         -------
  Warning  ProvisioningFailed  13s (x2 over 28s)  persistentvolume-controller  Failed to provision volume with StorageClass "storageos": failed to get secret from ["storageos"/"storageos-api"]
```

## Root Cause

For non Container Storage Interface (CSI) installations of Ondat, Kubernetes uses the Ondat API endpoint to communicate. If that communication fails, relevant actions such as create or mount volume can’t be transmitted to Ondat, hence the PVC will remain in `Pending` state. Ondat never received the action to perform, so it never sent back an acknowledgement.

- The `StorageClass` provisioned for Ondat references a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) from where it retrieves the API endpoint and the authentication parameters.
- If that secret is incorrect or missing, the connections won’t be established. It is common to see the secret has been deployed in a different namespace from where the `StorageClass` expects it, or that is has been deployed with a different name.

## Resolution

1. Ensure that you have successfully [deployed Ondat](/docs/install/) onto your Kubernetes or OpenShift cluster. If you are using the generated deployment manifests provided for [declarative installations](/docs/install/advanced/) to deploy Ondat,  make sure that the `StorageClass` parameters and the `Secret` reference match.

1. Check and ensure that the `StorageClass` parameters defined point to the correct location.

 ```yaml
 # Describe the Ondat StorageClass.
 kubectl get storageclass storageos --output yaml

 apiVersion: storage.k8s.io/v1
 kind: StorageClass
 metadata:
   labels:
     app: storageos
     app.kubernetes.io/component: storageclass
   name: storageos
 allowVolumeExpansion: true
 provisioner: csi.storageos.com
 parameters:
   csi.storage.k8s.io/fstype: ext4
   csi.storage.k8s.io/secret-name: storageos-api               # Secret name.
   csi.storage.k8s.io/secret-namespace: storageos              # Secret namespace.
 ```

 > 💡 Note that the parameters specify `secret-namespace` and `secret-name`.

1. Check and ensure that the secret exists in the namespace.

 ```bash
 # Check the secrets that are available in the "storageos" namespace.
 kubectl get secrets --namespace storageos

 NAME                          TYPE                      DATA   AGE
 sh.helm.release.v1.ondat.v1   helm.sh/release.v1        1      5h10m
 storageos-etcd-0              Opaque                    3      5h9m
 storageos-etcd-1              Opaque                    3      5h9m
 storageos-etcd-2              Opaque                    3      5h9m
 storageos-etcd-ca             Opaque                    2      5h10m
 storageos-etcd-client         Opaque                    3      5h10m
 storageos-etcd-secret         Opaque                    3      5h9m
 storageos-iot-keys            Opaque                    2      5h8m
 storageos-operator-webhook    Opaque                    4      5h10m
 storageos-portal-client       Opaque                    4      5h10m
 storageos-webhook             Opaque                    4      5h8m

 # Check to see if "storageos-api" secret exists.
 kubectl get secrets storageos-api --namespace storageos

 # Missing secret.
 No resources found.
 Error from server (NotFound): secrets "storageos-api" not found

 # The expected output returned to look like the example provided below:
 NAME            TYPE                      DATA   AGE
 storageos-api   kubernetes.io/storageos   2      5h11m
 ```
