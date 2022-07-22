---
title: "How To Enable Topology-Aware Placement (TAP)"
linkTitle: How To Enable Topology-Aware Placement (TAP)
---

## Overview

Ondat Topology-Aware Placement is a feature that enforces placement of data across failure domains to guarantee high availability.
- TAP uses default labels on nodes to define failure domains. For instance, an Availability Zone. However, the key label used to segment failure domains can be defined by the user per node. In addition, TAP is an opt-in feature per volume. 

> 💡 For more information on the Ondat Topology-Aware Placement feature, review the [Ondat Topology-Aware Placement](/docs/concepts/tap) feature page.

### Example - Enable Topology-Aware Placement Through a `PersistentVolumeClaim` Definition

The following guidance below will demonstrates how to use Ondat Topology-Aware Placement through a `PersistentVolumeClaim` (PVC) definition. 
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
kubectl describe nodes | grep "custom-region"
```

2. Create a custom `PersistentVolumeClaim` named `pvc-tap` and ensure that you add the following labels `storageos.com/topology-aware=true` and `storageos.com/topology-key=custom-region` to the manifest.

> 💡 If PVC label `storageos.com/topology-key` is not set, the node label `topology.kubernetes.io/zone` is used by default.

```yaml
# Create a "pvc-tap" PVC with TAP, custom topology key label called "custom-region" and "soft" failure mode is enabled.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-tap
  labels:
    storageos.com/topology-aware: "true"         # Enable Topology-Aware Placement.
    storageos.com/topology-key: custom-region    # Ensure that the topology failure domain node label is defined.
    storageos.com/failure-mode: soft             # Enable "soft" failure mode.
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```

3. Once the PVC resource has been successfully created, review and confirm that the `storageos.com/topology-aware: "true"`, `storageos.com/topology-key: custom-region` and `storageos.com/failure-mode: soft` labels have been applied.

```bash
# Get the labels applied to the "pvc-tap" PVC.
kubectl get pvc --output=wide --show-labels --namespace=default

NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE   LABELS
pvc-tap   Bound    pvc-abb18d51-7e1a-4812-8d65-40dbc090362a   5Gi        RWO            storageos      3m26s   Filesystem   storageos.com/failure-mode=soft,storageos.com/topology-aware=true,storageos.com/topology-key=custom-region
```

4. To quickly demonstrate Ondat TAP, use the `storageos.com/replicas` feature label to increase the number of volume replicas to `3` to match the number of `custom-region` zones that were defined in *Step 1*.
> 💡 To place 3 replicas, the cluster needs at least `4` nodes (`1` master + `3` replicas).
```bash
# Increase the volume replicas for "pvc-tap" to 3.
kubectl label pvc pvc-tap storageos.com/replicas=3
```

5. To review and confirm that Ondat TAP has successfully provisioned 3 volumes and evenly distributed in different `custom-region` zones - deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the  Ondat CLI utility pod name for later reference.

```bash
# Get the Ondat CLI utility pod name.
kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

storageos-cli-77885d6d8b-zqmnn
```

6. With the Ondat CLI now deployed, you can check the location of the master and replica volumes.

```bash
# Get the volumes in the `default` namespace using the Ondat CLI.
kubectl --namespace=storageos exec storageos-cli-77885d6d8b-zqmnn -- storageos get volumes --namespace=default

NAMESPACE  NAME                                      SIZE     LOCATION                     ATTACHED ON  REPLICAS  AGE
default    pvc-abb18d51-7e1a-4812-8d65-40dbc090362a  5.0 GiB  demo-worker-node-4 (online)               3/3       41 minutes ago

# Describe the `pvc-9af262b3-ab50-4d68-87bc-60eb825f1f99` volume.
kubectl --namespace=storageos exec storageos-cli-77885d6d8b-zqmnn -- storageos describe volume pvc-abb18d51-7e1a-4812-8d65-40dbc090362a --namespace=default

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
                    csi.storage.k8s.io/pvc/name=pvc-tap,
                    csi.storage.k8s.io/pvc/namespace=default,
                    storageos.com/failure-mode=soft,
                    storageos.com/nocompress=true,
                    storageos.com/replicas=3,
                    storageos.com/topology-aware=true,
                    storageos.com/topology-key=custom-region
Filesystem          ext4
Size                5.0 GiB (5368709120 bytes)
Version             OQ
Created at          2022-07-22T16:05:04Z (42 minutes ago)
Updated at          2022-07-22T16:26:35Z (21 minutes ago)

Master:
  ID                248ea74d-8753-4f64-afbf-73b72ddc211b
  Node              demo-worker-node-4 (1c9284c7-99a4-40c5-9ab9-95df19c1a8ac)
  Health            online
  Topology Domain   1

Replicas:
  ID                3172c40c-e745-48a9-91cf-39352389e99e
  Node              demo-worker-node-5 (37fdc95a-e215-44e7-a53d-45c1b7a7bad1)
  Health            ready
  Promotable        true
  Topology Domain   2

  ID                516bb457-4720-4b65-af70-327fb7d74898
  Node              demo-worker-node-3 (669e2d13-2520-4238-9be6-4f58540f0f64)
  Health            ready
  Promotable        true
  Topology Domain   3

  ID                e48d6084-8ce8-4d57-8644-20d61c28005e
  Node              demo-worker-node-1 (114ae6a7-c40d-40c2-87cb-1dc9dcc24348)
  Health            ready
  Promotable        true
  Topology Domain   1
```

> 💡  As demonstrated in the output above, notice how the master volume and each replica volume are deployed on a different nodes (`demo-worker-node-4`, `demo-worker-node-5`, `demo-worker-node-3` and `demo-worker-node-1` respectively) to ensure data protection and high availability in the event of a transient node failure.

### Example - Enable Topology-Aware Placement Through a `StorageClass` Definition

The following guidance below will demonstrates how to use Ondat Topology-Aware Placement through a `StorageClass` definition. 
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

2. Create a custom `StorageClass`, named `ondat-tap` and check that it has been successfully created.

```yaml
# Create the "ondat-tap" StorageClass.
cat <<EOF | kubectl create --filename -
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

3. Create a `PersistentVolumeClaim` that will use  `ondat-tap` as its `StorageClass` and confirm that it was successfully created.

```yaml
# Create a "pvc-tap-2" PVC that uses the "ondat-tap" StorageClass.
cat <<EOF | kubectl create --filename -
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
kubectl get pvc --output=wide --show-labels --namespace=default

NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE   LABELS
pvc-tap-2   Bound    pvc-d3662005-0bee-4b62-9a66-59ac65254687   5Gi        RWO            ondat-tap      4m    Filesystem   <none>
```

> 💡 Notice that the output above shows that the PVC does not have any labels applied to it - this is because we are using the `ondat-tap` StorageClass parameters defined in *Step 2*.

4. To review and confirm that Ondat TAP has successfully provisioned 2 volumes and evenly distributed in different zones - deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the  Ondat CLI utility pod name for later reference.

```bash
# Get the Ondat CLI utility pod name.
kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

storageos-cli-79787d586d-s2w66
```

6. With the Ondat CLI now deployed, you can check the location of the master and replica volumes.


```bash
# Get the volumes in the `default` namespace using the Ondat CLI.
kubectl --namespace=storageos exec storageos-cli-79787d586d-s2w66 -- storageos get volumes --namespace=default

NAMESPACE  NAME                                      SIZE     LOCATION                                  ATTACHED ON  REPLICAS  AGE
default    pvc-d3662005-0bee-4b62-9a66-59ac65254687  5.0 GiB  aks-storage-70602947-vmss000000 (online)               2/2       8 minutes ago

# Describe the `pvc-d3662005-0bee-4b62-9a66-59ac65254687` volume.
kubectl --namespace=storageos exec storageos-cli-79787d586d-s2w66 -- storageos describe volume pvc-d3662005-0bee-4b62-9a66-59ac65254687 --namespace=default

ID                  73d3e20a-1d48-472d-b64a-a1dfafceb593
Name                pvc-d3662005-0bee-4b62-9a66-59ac65254687
Description
AttachedOn
Attachment Type     detached
NFS
  Service Endpoint
  Exports:
Namespace           default (365ca0d2-4f24-4509-a3bd-7e026b8a7b63)
Labels              csi.storage.k8s.io/pv/name=pvc-d3662005-0bee-4b62-9a66-59ac65254687,
                    csi.storage.k8s.io/pvc/name=pvc-tap-2,
                    csi.storage.k8s.io/pvc/namespace=default,
                    storageos.com/nocompress=true,
                    storageos.com/replicas=2,
                    storageos.com/topology-aware=true
Filesystem          ext4
Size                5.0 GiB (5368709120 bytes)
Version             Mg
Created at          2022-07-22T17:52:54Z (9 minutes ago)
Updated at          2022-07-22T17:52:55Z (9 minutes ago)

Master:
  ID                11c2f323-e4a5-4864-861b-ed26501abbad
  Node              aks-storage-70602947-vmss000000 (52619a91-8246-46eb-91dd-d6741739ae0f)
  Health            online
  Topology Domain   northeurope-1

Replicas:
  ID                d681dfc8-7cce-4bac-a4ce-c3784a79e3bd
  Node              aks-storage-70602947-vmss000001 (84305a4d-d007-4552-9733-3ce634161124)
  Health            ready
  Promotable        true
  Topology Domain   northeurope-2

  ID                d9d3eb81-aec4-4093-bbee-f85e947e2f79
  Node              aks-default-53125611-vmss000002 (037dd333-9d68-4684-b40a-e0dcc8a53866)
  Health            ready
  Promotable        true
  Topology Domain   northeurope-3
```

> 💡  As demonstrated in the output above, notice how the master volume and each replica volume are deployed on a different nodes (`aks-storage-70602947-vmss000000`, `aks-storage-70602947-vmss000001` and `aks-default-53125611-vmss000002` respectively) to ensure data protection and high availability in the event of a transient node failure.