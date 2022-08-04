---
title: "How To Use Volume Replication"
linkTitle: How To Use Volume Replication
---

## Overview

> 💡 For more information on Ondat's Replication feature, review the [Replication](/docs/concepts/replication) feature page.

### Example - Enable Volume Replication Through a `PersistentVolumeClaim` Definition

The following guidance will demonstrate how to use Ondat's Volume Replication through a `PersistentVolumeClaim` (PVC) definition.
- The instructions will enable volume replication on a PVC with the label » `storageos.com/replicas=1` - which will create `1` master volume and `1` replica volume respectively.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a `StorageClass`.

1. Create a custom `PersistentVolumeClaim` named `pvc-replicated` and ensure that you add the following label >> `storageos.com/replicas=1` to the manifest.

    ```yaml
    # Create a "pvc-replicated" PVC that has a replica volume count of 1.
    cat <<EOF | kubectl create --filename -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-replicated
      labels:
        storageos.com/replicas: "1"                  # Replica volume count of 1
    spec:
      storageClassName: storageos
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

1. Once the PVC resource has been successfully created, review and confirm that the `storageos.com/replicas=1`, label has been applied.

    ```bash
    # Get the label applied to the "pvc-replicated" PVC.
    kubectl get pvc pvc-replicated --output=wide --show-labels --namespace=default

    NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
    pvc-replicated   Bound    pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c   5Gi        RWO            storageos      26s   Filesystem   storageos.com/replicas=1```
    ```

1. To review and confirm that Ondat has successfully provisioned `1` master volume and `1` replica volume as defined in the PVC manifest earlier - deploy and run the  [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

    ```bash
    # Get the Ondat CLI utility pod name.
    kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

    storageos-cli-77885d6d8b-mgbr8
    ```

1. With the Ondat CLI now deployed, you can check the count and location of the master and replica volumes created for `pvc-replicated`.

    ```bash
    # Get the volumes in the "default" namespace using the Ondat CLI.
    kubectl --namespace=storageos exec storageos-cli-77885d6d8b-mgbr8 -- storageos get volumes --namespace=default

    NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON  REPLICAS  AGE
    default    pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c  5.0 GiB  demo-worker-node-1 (online)               1/1       8 minutes ago

    # Describe the "pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c" volume.
    kubectl --namespace=storageos exec storageos-cli-77885d6d8b-mgbr8 -- storageos describe volume pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c --namespace=default

    ID                  495eb6a5-28de-4593-b6bc-d91094b52326
    Name                pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c
    Description
    AttachedOn
    Attachment Type     detached
    NFS
      Service Endpoint
      Exports:
    Namespace           default (b4c020a6-6c54-40cd-a502-9ea4f4b68a9c)
    Labels              csi.storage.k8s.io/pv/name=pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c,
                        csi.storage.k8s.io/pvc/name=pvc-replicated,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/nocompress=true,
                        storageos.com/replicas=1
    Filesystem          ext4
    Size                5.0 GiB (5368709120 bytes)
    Version             Mg
    Created at          2022-07-25T16:47:51Z (10 minutes ago)
    Updated at          2022-07-25T16:47:53Z (10 minutes ago)

    Master:
      ID                24a56198-1648-46af-ac25-71d02ecba31c
      Node              demo-worker-node-1 (d7a745ff-242a-48f4-a6bf-4f191c14a237)
      Health            online

    Replicas:
      ID                b7f565c6-860b-4458-aeb2-c2f623da77af
      Node              demo-worker-node-4 (cad83b41-89b7-4520-9b82-632f31d94814)
      Health            ready
      Promotable        true
    ```

    > 💡 As demonstrated in the output above, notice the number of master replica volumes created and which node they are located on. If we created a volume without a replica count defined in *Step 1* - only the master volume would be provisioned.

### Example - Enable Volume Replication Through a `StorageClass` Definition

The following guidance will demonstrate how to use Ondat's Volume Replication  through a `StorageClass` (PVC) definition.
- The instructions will enable volume replication through a custom `StorageClass` and use the following parameter » `storageos.com/replicas=2` - which will create `1` master volume and `2` replica volumes respectively.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a `StorageClass`.

1. Create a custom `StorageClass`, named `ondat-replicated` and check that it has been successfully created.

    ```yaml
    # Create the "ondat-replicated" StorageClass.
    cat <<EOF | kubectl create --filename -
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ondat-replicated
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      storageos.com/replicas: "2"
      csi.storage.k8s.io/fstype: ext4
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    EOF
    ```

    ```bash
    # Review and confirm that "ondat-replicated" was created.
    kubectl get sc | grep "ondat-replicated"
    ```

1. Create a `PersistentVolumeClaim` that will use `ondat-replicated` as its `StorageClass` and confirm that it was successfully created.

    ```yaml
    # Create a "pvc-replicated-2" PVC that uses the "ondat-replicated" StorageClass.
    cat <<EOF | kubectl create --filename -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-replicated-2
    spec:
      storageClassName: ondat-replicated         # Use the "ondat-replicated" StoragClass created in Step 1
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

    ```bash
    # Ensure that the PVC was successfully provisioned with "ondat-replicated".
    kubectl get pvc pvc-replicated-2 --output=wide --show-labels --namespace=default

    NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE   VOLUMEMODE   LABELS
    pvc-replicated-2   Bound    pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646   5Gi        RWO            ondat-replicated   57s   Filesystem   <none>
    ```

    > 💡 Notice that the output above shows that the PVC does not have any labels applied to it - this is because we are using the `ondat-replicated` StorageClass parameters defined in *Step 1*.

1. To review and confirm that Ondat has successfully provisioned `1` master volume and `2` replica volume as defined in the `StorageClass` manifest earlier - deploy and run the  [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

    ```bash
    # Get the Ondat CLI utility pod name.
    kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

    storageos-cli-77885d6d8b-mgbr8
    ```

1. With the Ondat CLI now deployed, you can check the count and location of the master and replica volumes created for `pvc-replicated-2`.

    ```bash
    # Get the volumes in the "default" namespace using the Ondat CLI.
    kubectl --namespace=storageos exec storageos-cli-77885d6d8b-mgbr8 -- storageos get volumes --namespace=default

    NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON  REPLICAS  AGE
    default    pvc-7fed5a56-42b2-4fe3-bcab-e31c97931b8c  5.0 GiB  demo-worker-node-1 (online)               1/1       29 minutes ago
    default    pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646  5.0 GiB  demo-worker-node-3 (online)               2/2       4 minutes ago



    # Describe the "pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646" volume.
    kubectl --namespace=storageos exec storageos-cli-77885d6d8b-mgbr8 -- storageos describe volume pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646 --namespace=default

    ID                  52904e9e-624a-4d56-a7bd-5d353d8701a2
    Name                pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646
    Description
    AttachedOn
    Attachment Type     detached
    NFS
      Service Endpoint
      Exports:
    Namespace           default (b4c020a6-6c54-40cd-a502-9ea4f4b68a9c)
    Labels              csi.storage.k8s.io/pv/name=pvc-c5f4e448-e78e-4ece-ad24-f65c3e04d646,
                        csi.storage.k8s.io/pvc/name=pvc-replicated-2,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/nocompress=true,
                        storageos.com/replicas=2
    Filesystem          ext4
    Size                5.0 GiB (5368709120 bytes)
    Version             Mg
    Created at          2022-07-25T17:12:32Z (5 minutes ago)
    Updated at          2022-07-25T17:12:33Z (5 minutes ago)

    Master:
      ID                e6ba1c26-ba35-4f2f-b3cb-606c259191b5
      Node              demo-worker-node-3 (1b78adea-6301-4155-95a4-8fab26cc1038)
      Health            online

    Replicas:
      ID                6f4a9655-841b-4313-b548-32bdbcd50ea6
      Node              demo-worker-node-2 (3957692d-dee2-4a4e-9ddc-845b7b0a1fbe)
      Health            ready
      Promotable        true

      ID                b6dd25ab-e338-4555-9c67-aa35dc93ad28
      Node              demo-worker-node-1 (d7a745ff-242a-48f4-a6bf-4f191c14a237)
      Health            ready
      Promotable        true
    ```

    > 💡 As demonstrated in the output above, notice the number of master replica volumes created and which node they are located on. If we created a volume without a replica count defined in *Step 1* - only the master volume would be provisioned.
