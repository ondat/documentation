---
title: "How To Enable CSI Allowed Toplogies"
linkTitle: How To Enable CSI Allowed Topologies
---

## Overview

The CSI Allowed Topologies feature lets you specify sub-divisions of a cluster
for a volume to be placed in. For detailed information on it, please review the
[Ondat CSI Allowed Topologies](/docs/concepts/csi-allowed-topologies) feature page.

CSI Allowed Topologies are enabled by applying a `storageos.com/fixed-topology:
"true"` label to any PVC that uses a StorageClass with an `allowedTopologies` block.

### Node Label Precautions

For Ondat, the only node label available to use in `allowedTopologies` is
`topology.kubernetes.io/zone`, the Kubernetes' default label for representing
"a logical failure domain". Please note that this label is often preset and/or
overwritten by cloud providers through the Kubernetes cloud-provider
interface (more information on that [here](https://kubernetes.io/docs/reference/labels-annotations-taints/#topologykubernetesiozone)).

As such, manually overwriting these values yourself should be done with caution,
check your cloud provider's behaviour before making changes outside of testing
environments.

### Usage Notes

- This feature is mutually exclusive with Ondat's
  [Topology-Aware-Provisioning](/docs/operations/tap) feature. A volume
  specifying both labels will fail to provision.
- Your nodes must have the required label key, otherwise volumes with the label
  will fail to provision.
- There must exist nodes with the labels values specified on your
  StorageClass, otherwise the volume will fail to be placed.

## Example Usage

These instructions will ensure your cluster is correctly labelled to use the
feature, create an Allowed Topologies StorageClass, and create a PVC using the
StorageClass and the Allowed Topologies feature.

1. In the code snippet below, we set a custom value for the 'zone' label for each of our nodes.

    > 💡Please see the 'Node Lable Precautions' section above for warnings on manually setting this label in production.

    ```bash
    # Label the worker nodes to define custom zones.
    kubectl label node demo-worker-node-1 topology.kubernetes.io/zone=zone-1
    kubectl label node demo-worker-node-2 topology.kubernetes.io/zone=zone-2
    kubectl label node demo-worker-node-3 topology.kubernetes.io/zone=zone-3
    kubectl label node demo-worker-node-4 topology.kubernetes.io/zone=zone-4
    kubectl label node demo-worker-node-5 topology.kubernetes.io/zone=zone-5

    # Check that the worker nodes have been labeled successfully.
    kubectl describe nodes | grep "topology.kubernetes.io/zone"
    ```

1. Create a custom `StorageClass`, with an `allowedTopologies` block and check that it has been successfully created.

    ```yaml
    # Create the "ondat-allowed-topologies" StorageClass.
    kubectl create -f-<<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ondat-allowed-topologies
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      csi.storage.k8s.io/fstype: ext4
      storageos.com/replicas: "1"
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    allowedTopologies:
    - matchLabelExpressions:
      - key: topology.kubernetes.io/zone
        values:
        - zone-1
        - zone-2
    EOF
    ```

    ```bash
    # Review and confirm that "ondat-allowed-topologies" was created.
    kubectl get sc | grep "ondat-allowed-topologies"
    ```

1. Create a custom `PersistentVolumeClaim` with the `storageos.com/fixed-topologies=true` label and refrencing the previously created StorageClass.

    ```yaml
    # Create a "allowed-topologies-pvc" PVC with 1 replica and the `storageos.com/fixed-topologies=true` label.
    kubectl create -f-<<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: allowed-topologies-pvc
      labels:
        storageos.com/replicas: "1"
        storageos.com/fixed-topology: "true"
    spec:
      storageClassName: ondat-allowed-topologies
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    EOF
    ```

1. Once the PVC resource has been successfully created, review and confirm that the labels and StorageClass have been set correctly.

    ```bash
    # Get the labels applied to the "pvc-allowed-topologies" PVC.
    kubectl get pvc -owide --show-labels

    NAME                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS               AGE    VOLUMEMODE   LABELS
    allowed-topologies-pvc   Bound    pvc-abb18d51-7e1a-4812-8d65-40dbc090362a   5Gi        RWO            ondat-allowed-topologies   107s   Filesystem   storageos.com/fixed-topology=true,storageos.com/replicas=1
    ```

1. To confirm that Ondat has successfully provisioned volume deployments in the right topologies (the two zones specified in the StorageClass) deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`.

1. With the Ondat CLI now deployed, you can check the location of the master and replica volumes.

    ```bash
    # Get the volumes in the "default" namespace using the Ondat CLI.
    kubectl -n storageos exec deploy/storageos-cli -- storageos get volumes -A

    NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON  REPLICAS  AGE
    default    pvc-abb18d51-7e1a-4812-8d65-40dbc090362a  5.0 GiB  demo-worker-node-2 (online)               1/1       41 minutes ago

    # Describe the volume.
    kubectl -n storageos exec deploy/storageos-cli -- storageos describe volume pvc-abb18d51-7e1a-4812-8d65-40dbc090362a -n default

    ID                  882ab4dd-1b35-4bb4-a825-68763719b991
    Name                pvc-abb18d51-7e1a-4812-8d65-40dbc090362a
    Description
    AttachedOn
    Attachment Type     detached
    NFS
      Service Endpoint
      Exports:
    Namespace           default (5055ae9d-6278-4374-a6c8-e4779c6cc58f)
    Labels              csi.storage.k8s.io/pv/name=pvc-abb18d51-7e1a-4812-8d65-40dbc090362a,
                        csi.storage.k8s.io/pvc/name=allowed-topologies-pvc,
                        csi.storage.k8s.io/pvc/namespace=default,
                        storageos.com/fixed-topologies=true,
                        storageos.com/replicas=1,
    Topology Preferences
      Requisite Zones:    [zone-1, zone-2]
      Preferred Zones:    [zone-1, zone-2]
    Filesystem          ext4
    Size                5.0 GiB (5368709120 bytes)
    Version             OQ
    Created at          2022-07-22T16:05:04Z (42 minutes ago)
    Updated at          2022-07-22T16:26:35Z (21 minutes ago)

    Master:
      ID                248ea74d-8753-4f64-afbf-73b72ddc211b
      Node              demo-worker-node-2 (1c9284c7-99a4-40c5-9ab9-95df19c1a8ac)
      Health            online

    Replicas:
      ID                e48d6084-8ce8-4d57-8644-20d61c28005e
      Node              demo-worker-node-1 (114ae6a7-c40d-40c2-87cb-1dc9dcc24348)
      Health            ready
      Promotable        true
    ```

    > 💡  As demonstrated in the output above, the 2 deployments of the volume are on nodes in the two topologies specified in the StorageClass (zone-1 and zone-2)
