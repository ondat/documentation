---
title: "How To Enable Data Compression"
linkTitle: How To Enable Data Compression
---

## Overview

> 💡 For more information on Ondat's Compression feature, review the [Compression](/docs/concepts/compression)  feature page.

### Example - Enable Data Compression Through a `PersistentVolumeClaim` Definition

The following guidance below will demonstrates how to use Ondat’s Data Compression feature through a `PersistentVolumeClaim` (PVC) definition.

- The instructions will enable compression on a PVC with the label »  `storageos.com/nocompress=false` for the Ondat volume that will be provisioned.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a  `StorageClass`.

1. Create a custom  `PersistentVolumeClaim`  named  `pvc-compressed`  and ensure that you add the following label »  `storageos.com/nocompress=false`  to the manifest.

    ```yaml
    # Create a "pvc-compressed" PVC that enables data compression.
    cat <<EOF | kubectl create --filename -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-compressed
      labels:
        storageos.com/nocompress: "false"           # Enable compression of data-at-rest and data-in-transit.
    spec:
      storageClassName: storageos
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

1. Once the PVC resource has been successfully created, review and confirm that the  `storageos.com/nocompress=false`, label has been applied.

    ```bash
    # Get the label applied to the "pvc-replicated" PVC.
    kubectl get pvc pvc-compressed --output=wide --show-labels --namespace=default

    NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
    pvc-compressed   Bound    pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a   5Gi        RWO            storageos      15s   Filesystem   storageos.com/nocompress=false
    ```

1. To review and confirm that Ondat has successfully provisioned a volume that has compression enabled as defined in the PVC manifest earlier - deploy and run the  [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster)  first, so that you can interact and manage Ondat through  `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

    ```bash
    # Get the Ondat CLI utility pod name.
    kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

    storageos-cli-79787d586d-qp9dj
    ```

1. With the Ondat CLI now deployed, you can check the volume created for  `pvc-compressed` and confirm if it has compression enabled.

    ```bash
    # Get the volumes in the "default" namespace using the Ondat CLI.
    kubectl --namespace=storageos exec storageos-cli-79787d586d-qp9dj -- storageos get volumes --namespace=default

    NAMESPACE  NAME                                      SIZE     LOCATION                                  ATTACHED ON  REPLICAS  AGE
    default    pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a  5.0 GiB  aks-storage-56882587-vmss000000 (online)               0/0       2 minutes ago


    # Describe the "pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a" volume.
    kubectl --namespace=storageos exec storageos-cli-79787d586d-qp9dj -- storageos describe volume pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a --namespace=default

    ID                  e1c7e565-4be7-414f-910f-86d97652e8c3
    Name                pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a
    Description
    AttachedOn
    Attachment Type     detached
    NFS
      Service Endpoint
      Exports:
    Namespace           default (371b17d3-6778-4085-b943-6d032e1b5f34)
    Labels              csi.storage.k8s.io/pv/name=pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a,
                        csi.storage.k8s.io/pvc/name=pvc-compressed,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/nocompress=false
    Filesystem          ext4
    Size                5.0 GiB (5368709120 bytes)
    Version             Mg
    Created at          2022-07-26T15:49:26Z (4 minutes ago)
    Updated at          2022-07-26T15:49:26Z (4 minutes ago)

    Master:
      ID                2f3642b3-a1f0-4dd3-8cc7-7e24bda5a144
      Node              aks-storage-56882587-vmss000000 (a28e5c43-5847-4968-b777-3bd618d4424e)
      Health            online
    ```

    > 💡 Notice in the label metadata section - there is a label >> `storageos.com/nocompress=false` attached to the volume that was provisioned.

### Example - Enable Data Compression Through a `StorageClass` Definition

The following guidance below will demonstrates how to use Ondat’s Data Compression feature through a  `StorageClass`  (PVC) definition.

- The instructions will enable compression through a custom  `StorageClass`  and use the following parameter »  `storageos.com/nocompress=false`  - which will be used to create an Ondat volume.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a  `StorageClass`.

1. Create a custom  `StorageClass`, named  `ondat-compressed`  and check that it has been successfully created.

    ```yaml
    # Create the "ondat-compressed" StorageClass.
    cat <<EOF | kubectl create --filename -
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ondat-compressed
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      storageos.com/nocompress: "false"           # Enable compression of data-at-rest and data-in-transit.
      csi.storage.k8s.io/fstype: ext4
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    EOF
    ```

    ```bash
    # Review and confirm that "ondat-compressed" was created.
    kubectl get sc | grep "ondat-compressed"

    ondat-compressed        csi.storageos.com    Delete          Immediate              true                   92s
    ```

1. Create a  `PersistentVolumeClaim`  that will use  `ondat-replicated`  as its  `StorageClass`  and confirm that it was successfully created.

    ```yaml
    # Create a "pvc-compressed-2" PVC that uses the "ondat-compressed" StorageClass.
    cat <<EOF | kubectl create --filename -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-compressed-2
    spec:
      storageClassName: ondat-compressed         # Use the "ondat-compressed" StoragClass created in Step 1
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

    ```bash
    # Ensure that the PVC was successfully provisioned with "ondat-compressed".
    kubectl get pvc pvc-compressed-2 --output=wide --show-labels --namespace=default

    NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE   VOLUMEMODE   LABELS
    pvc-compressed-2   Bound    pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820   5Gi        RWO            ondat-compressed   8s    Filesystem   <none>
    ```

    > 💡 Notice that the output above shows that the PVC does not have any labels applied to it - this is because we are using the `ondat-compressed` StorageClass parameters defined in _Step 1_.

1. To review and confirm that Ondat has successfully provisioned a volume that has compression enabled as defined in the PVC manifest earlier - deploy and run the  [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster)  first, so that you can interact and manage Ondat through  `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

    ```bash
    # Get the Ondat CLI utility pod name.
    kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

    storageos-cli-79787d586d-qp9dj
    ```

1. With the Ondat CLI now deployed, you can check the volume created for  `pvc-compressed-2` and confirm if it has compression enabled.

    ```bash
    # Get the volumes in the "default" namespace using the Ondat CLI.
    kubectl --namespace=storageos exec storageos-cli-79787d586d-qp9dj -- storageos get volumes --namespace=default

    NAMESPACE  NAME                                      SIZE     LOCATION                                  ATTACHED ON  REPLICAS  AGE
    default    pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820  5.0 GiB  aks-storage-56882587-vmss000001 (online)               0/0       6 minutes ago
    default    pvc-4457be86-54a3-4f2b-8326-5d4c8799d48a  5.0 GiB  aks-storage-56882587-vmss000000 (online)               0/0       23 minutes ago

    # Describe the "pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820" volume.
    kubectl --namespace=storageos exec storageos-cli-79787d586d-qp9dj -- storageos describe volume pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820 --namespace=default

    ID                  b9ee19fe-f1ab-4099-bae7-34a52323ee55
    Name                pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820
    Description
    AttachedOn
    Attachment Type     detached
    NFS
      Service Endpoint
      Exports:
    Namespace           default (371b17d3-6778-4085-b943-6d032e1b5f34)
    Labels              csi.storage.k8s.io/pv/name=pvc-07e8a7db-fc77-40cf-a4c9-62952da6f820,
                        csi.storage.k8s.io/pvc/name=pvc-compressed-2,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/nocompress=false
    Filesystem          ext4
    Size                5.0 GiB (5368709120 bytes)
    Version             Mg
    Created at          2022-07-26T16:06:03Z (8 minutes ago)
    Updated at          2022-07-26T16:06:04Z (8 minutes ago)

    Master:
      ID                f2fbfad3-b5d7-4d36-96d4-5c54a4bf8946
      Node              aks-storage-56882587-vmss000001 (43391062-73d5-4231-ab46-f10ef748bee6)
      Health            online
    ```

    > 💡 Notice in the label metadata section - there is a label >> `storageos.com/nocompress=false` attached to the volume that was provisioned.
