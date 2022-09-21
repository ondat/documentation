---
title: "How To Enable Topology-Aware Placement (TAP)"
linkTitle: How To Enable Topology-Aware Placement (TAP)
---

## Overview

Ondat Topology-Aware Placement is a feature that enforces placement of data across failure domains to guarantee high availability.

- TAP uses default labels on nodes to define failure domains. For instance, an Availability Zone. However, the key label used to segment failure domains can be defined by the user per node. In addition, TAP is an opt-in feature per volume.

> 💡 For more information on the Ondat Topology-Aware Placement feature, review the [Ondat Topology-Aware Placement](/docs/concepts/tap) feature page.

### Example - Enable Topology-Aware Placement Through a `PersistentVolumeClaim` Definition

The following guidance will demonstrate how to use Ondat Topology-Aware Placement through a `PersistentVolumeClaim` (PVC) definition.

- The instructions will enable Topology-Aware Placement on a PVC, use a custom zone labelling scheme with the label >> `storageos.com/topology-key=custom-region` and set it to the `soft` Failure Mode.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a StorageClass.

1. In the code snippet below, we will define a custom node zone label using the following key-value pair layout >> `custom-region=<integer>` and apply it against the nodes.

    ```bash
    # Label the worker nodes to define custom regions for the TAP feature.
    kubectl label node demo-worker-node-1 custom-region=1
    kubectl label node demo-worker-node-2 custom-region=2
    kubectl label node demo-worker-node-3 custom-region=3
    kubectl label node demo-worker-node-4 custom-region=1
    kubectl label node demo-worker-node-5 custom-region=2

    # Check that the worker nodes have been labeled successfully.
    kubectl describe nodes | grep -C 10 "custom-region"
    ```

1. Create a custom `PersistentVolumeClaim` named `pvc-tap` and ensure that you add the following labels `storageos.com/topology-aware=true` and `storageos.com/topology-key=custom-region` to the manifest.

    > 💡 If PVC label `storageos.com/topology-key` is not set, the node label `topology.kubernetes.io/zone` is used by default.

    ```yaml
    # Create a "pvc-tap" PVC with TAP, custom topology key label called "custom-region" and "soft" failure mode is enabled.
    $ kubectl create -f-<<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-topology-aware-placement
      labels:
        storageos.com/topology-aware: "true"         # Enable Topology-Aware Placement.
        storageos.com/topology-key: custom-region    # Ensure that the topology failure domain node label is defined.
        storageos.com/failure-mode: soft             # Enable "soft" failure mode.
        storageos.com/replicas: "2"
    spec:
      storageClassName: storageos
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

1. Once the PVC resource has been successfully created, review and confirm that the `storageos.com/topology-aware: "true"`, `storageos.com/topology-key: custom-region` and `storageos.com/failure-mode: soft` labels have been applied.

    ```bash
    # Get the labels applied to the "pvc-tap" PVC.
    $ kubectl get pvc --show-labels pvc-topology-aware-placement
    NAME                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   LABELS
    pvc-topology-aware-placement   Bound    pvc-b785737c-fc51-40a7-bf83-c1d660a222a3   5Gi        RWO            storageos      81s   storageos.com/replicas=2,storageos.com/topology-aware=true
    ```

1. Check data placement

    Check that the primary of the volume and its replicas are placed on different failure domains defined by your custom label.

    > 💡 To place 2 replicas, the cluster needs at least `3` nodes (`1` primary + `2` replicas). Because of the use of the soft failure-mode, the volume could operate with 2 nodes while waiting to be able to place a new replica, eventaully. 

    ```bash
    $ PV=pvc-b785737c-fc51-40a7-bf83-c1d660a222a3
    $ kubectl describe volume $PV # volume[s] = volumes.api.storageos.com
    ...
    Spec:
      Config Labels:
        csi.storage.k8s.io/pv/name:        pvc-b785737c-fc51-40a7-bf83-c1d660a222a3
        csi.storage.k8s.io/pvc/name:       pvc-topology-aware-placement
        csi.storage.k8s.io/pvc/namespace:  default
        storageos.com/nocompress:          true
        storageos.com/replicas:            2
        storageos.com/topology-aware:      true
      Fs Type:                             ext4
      Nfs:
      Replicas:    2
      Size Bytes:  5368709120
    Status:
      Attachment Type:  detached
      Master:
        Health:      online
        Hostname:    demo-worker-node-1
        Id:          d13623ab-78b6-4a4e-b971-c370b185c35c
        Node ID:     99efd6b4-3cb4-4e20-a6e4-dbf9c97b7712
        Promotable:  true
      Replicas:
        Health:      ready
        Hostname:    demo-worker-node-3
        Id:          39e9cc03-c2e3-4eea-9a08-2b3ad5afd9b6
        Node ID:     d9a63f17-e07c-41d5-a9c5-5264bc896601
        Promotable:  true
        Sync Progress:
        Health:      ready
        Hostname:    demo-worker-node-2
        Id:          f0c9a5f8-8034-4524-99cf-0e5602dfd70e
        Node ID:     defbb2fa-66f5-40b3-86a7-7a167ba2e1ae
        Promotable:  true
        Sync Progress:
      Volume Id:  3d70627d-5122-4255-839b-22f7215393fc
    ...
    ```

    > 💡  As demonstrated in the output above, notice how the primary volume and each replica volume are deployed on different nodes belonging to different failure domains.

### Example - Enable Topology-Aware Placement Through a `StorageClass` Definition

The following guidance will demonstrate how to use Ondat Topology-Aware Placement through a `StorageClass` definition.

- The instructions will enable Topology-Aware Placement through a custom StorageClass, use the node label >> `topology.kubernetes.io/zone` and set the default volume replica count >> `storageos.com/replicas` to `2`.

    > 💡 Labels can be applied to a PVC directly, or indirectly by adding them as parameters on a StorageClass.

1. Check and confirm that the worker nodes in your cluster have the `topology.kubernetes.io/zone` already applied to them first.

    > 💡 Major Cloud Provider Kubernetes distributions such as GKE, EKS and AKS have `topology.kubernetes.io/zone` applied to worker nodes that are deployed in different availability zones.

    ```bash
    # Check for the "topology.kubernetes.io/zone" first.
    kubectl describe nodes | grep "topology.kubernetes.io/zone="

    topology.kubernetes.io/zone=northeurope-1
    topology.kubernetes.io/zone=northeurope-2
    topology.kubernetes.io/zone=northeurope-3
    topology.kubernetes.io/zone=northeurope-1
    topology.kubernetes.io/zone=northeurope-2
    ```

1. Create a custom `StorageClass`, named `ondat-tap` and check that it has been successfully created.

    ```yaml
    # Create the "ondat-tap" StorageClass.
    $ kubectl create -f-<<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ondat-tap
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      csi.storage.k8s.io/fstype: ext4
      storageos.com/replicas: "2"
      storageos.com/topology-aware: "true"
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    EOF
    ```

    ```bash
    # Review and confirm that "ondat-tap" was created.
    kubectl get sc | grep "ondat-tap"
    ```

1. Create a `PersistentVolumeClaim` that will use `ondat-tap` as its `StorageClass` and confirm that it was successfully created.

    ```yaml
    # Create a "pvc-tap-2" PVC that uses the "ondat-tap" StorageClass.
    $ kubectl create -f-<<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-tap-2
    spec:
      storageClassName: ondat-tap
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

    ```bash
    # Ensure that the PVC was successfully provisioned with "ondat-tap".
    kubectl get pvc -owide --show-labels

    NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
    pvc-tap-2   Bound    pvc-d3662005-0bee-4b62-9a66-59ac65254687   5Gi        RWO            ondat-tap      4m    Filesystem   <none>
    ```

    > 💡 Notice that the output above shows that the PVC does not have any labels applied to it - this is because we are using the `ondat-tap` StorageClass parameters defined in *Step 2*.

1. Validate data placement

    ```bash
    $ PV=pvc-d3662005-0bee-4b62-9a66-59ac65254687
    $ kubectl describe volume $PV # volume[s] = volumes.api.storageos.com
    ```
