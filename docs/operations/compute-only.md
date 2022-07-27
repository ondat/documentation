---
title: "How To Setup A Centralised Cluster Topology"
linkTitle: How To Setup A Centralised Cluster Topology
---

## Overview

With Ondat, cluster administrators can set the `storageos.com/computeonly` label against Kubernetes nodes that they want to dedicate to running compute intensive workloads.
> 💡 For more information on the Centralised Cluster Topology model, review the [Cluster Topologies](/docs/concepts/cluster-topologies) feature page.

### Example - Configuring A Centralised Cluster Topology

The following guidance below will demonstrates how to create a centralised cluster topology model by using Ondat's >> `storageos.com/computeonly=true` node label.
> 💡 In this guideline, we are using an [Azure Kubernetes Service (AKS)](/docs/install/microsoft-azure-aks/) cluster to demonstrate how to configure a centralised cluster topology model.

1. Get the list of nodes in your Kubernetes cluster.

```bash
# List the nodes available in the cluster.
kubectl get nodes --output wide

NAME                              STATUS   ROLES   AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-default-26276352-vmss000000   Ready    agent   28m   v1.23.5   10.224.0.4    <none>        Ubuntu 18.04.6 LTS   5.4.0-1085-azure   containerd://1.5.11+azure-2
aks-default-26276352-vmss000001   Ready    agent   27m   v1.23.5   10.224.0.5    <none>        Ubuntu 18.04.6 LTS   5.4.0-1085-azure   containerd://1.5.11+azure-2
aks-default-26276352-vmss000002   Ready    agent   27m   v1.23.5   10.224.0.6    <none>        Ubuntu 18.04.6 LTS   5.4.0-1085-azure   containerd://1.5.11+azure-2
aks-storage-78891087-vmss000000   Ready    agent   24m   v1.23.5   10.224.0.7    <none>        Ubuntu 18.04.6 LTS   5.4.0-1085-azure   containerd://1.5.11+azure-2
aks-storage-78891087-vmss000001   Ready    agent   24m   v1.23.5   10.224.0.8    <none>        Ubuntu 18.04.6 LTS   5.4.0-1085-azure   containerd://1.5.11+azure-2
```

2. Using the the output, we are going to label the nodes that begin with the prefix >> `aks-default-` with `storageos.com/computeonly=true`, whilst we dedicate nodes that begin with the prefix >> `aks-storage-` as storage nodes.
```bash
# Label the "aks-default-*" nodes with the "storageos.com/computeonly=true" feature label.
kubectl label node aks-default-26276352-vmss000000 storageos.com/computeonly=true
kubectl label node aks-default-26276352-vmss000001 storageos.com/computeonly=true
kubectl label node aks-default-26276352-vmss000002 storageos.com/computeonly=true

# Check that the nodes have been labeled successfully.
kubectl describe node aks-default-26276352-vmss000000 | grep "computeonly"
kubectl describe node aks-default-26276352-vmss000001 | grep "computeonly"
kubectl describe node aks-default-26276352-vmss000002 | grep "computeonly"
```

3. Now we have labelled nodes with >> `storageos.com/computeonly=true` - the next step will be to [install Ondat](/docs/install/) onto the cluster. 
    - Ensure that you have met the prerequisites for the Kubernetes distribution that you will be using for the Ondat deployment.

4. Once we have successfully deployed Ondat, we are also going to deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster)  first, so that you can interact and manage Ondat alongside `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

```bash
# Get the Ondat CLI utility pod name.
kubectl --namespace=storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli

storageos-cli-79787d586d-fkjnk
```

5. To test that the `storageos.com/computeonly=true` is working - create `2` custom  `PersistentVolumeClaim` definitions  named - `pvc-replicated-centralised-topology` and `pvc-replicated-centralised-topology-test` that use the following specifications below;

```yaml
# Create a "pvc-replicated-centralised-topology" PVC that has a replica volume count of 1.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-replicated-centralised-topology
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

```yaml
# Create a "pvc-replicated-centralised-topology-test" PVC that has a replica volume count of 3.
cat <<EOF | kubectl create --filename -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-replicated-centralised-topology-test
  labels:
    storageos.com/replicas: "3"                  # Replica volume count of 3
spec:
  storageClassName: storageos
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
```

6.  With the Ondat CLI and `kubectl`, you can check to see which Ondat volumes have been provisioned and the node location where the volumes reside.

```bash
# List the PVCs that have been created in the previous step.
kubectl get pvc --output=wide --namespace=default

NAME                                       STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE
pvc-replicated-centralised-topology        Bound     pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2   5Gi        RWO            storageos      5m9s    Filesystem
pvc-replicated-centralised-topology-test   Pending                                                                        storageos      4m32s   Filesystem

# List the PVs that have been created.
kubectl get pv --output=wide

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                         STORAGECLASS   REASON   AGE    VOLUMEMODE
pvc-2043e1d5-880f-4ac4-8644-357673709a02   12Gi       RWO            Delete           Bound    storageos-etcd/storageos-etcd-2               default                 99m    Filesystem
pvc-404de0a0-12f3-4397-83ae-5160133dd4a6   12Gi       RWO            Delete           Bound    storageos-etcd/storageos-etcd-4               default                 98m    Filesystem
pvc-62ea2e89-b980-4b28-a1cf-8ac9df522cef   12Gi       RWO            Delete           Bound    storageos-etcd/storageos-etcd-3               default                 99m    Filesystem
pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2   5Gi        RWO            Delete           Bound    default/pvc-replicated-centralised-topology   storageos               5m8s   Filesystem
pvc-741604ef-20c0-4219-bdb4-944d1371f684   12Gi       RWO            Delete           Bound    storageos-etcd/storageos-etcd-1               default                 99m    Filesystem
pvc-e8564514-dd7a-4f39-8a60-76cee4cb6452   12Gi       RWO            Delete           Bound    storageos-etcd/storageos-etcd-0               default                 99m    Filesystem
```

```bash
# Get the volumes in the "default" namespace using the Ondat CLI.
kubectl --namespace=storageos exec storageos-cli-79787d586d-fkjnk -- storageos get volumes --namespace=default

NAMESPACE  NAME                                      SIZE     LOCATION                                  ATTACHED ON  REPLICAS  AGE
default    pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2  5.0 GiB  aks-storage-78891087-vmss000001 (online)               1/1       7 minutes ago

# Describe the "pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2" volume.
kubectl --namespace=storageos exec storageos-cli-79787d586d-fkjnk -- storageos describe volume pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2 --namespace=default

ID                  ae1e21c1-d5d2-44ef-9057-29185bb7de13
Name                pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2
Description
AttachedOn
Attachment Type     detached
NFS
  Service Endpoint
  Exports:
Namespace           default (ebf3984a-cbe1-47ff-8c47-19d3e94cfeb4)
Labels              csi.storage.k8s.io/pv/name=pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2,
                    csi.storage.k8s.io/pvc/name=pvc-replicated-centralised-topology,
                    csi.storage.k8s.io/pvc/namespace=default,
                    storageos.com/nocompress=true,
                    storageos.com/replicas=1
Filesystem          ext4
Size                5.0 GiB (5368709120 bytes)
Version             Mg
Created at          2022-07-27T13:26:35Z (26 minutes ago)
Updated at          2022-07-27T13:26:36Z (26 minutes ago)

Master:
  ID                b6311c1f-e7e6-4ca6-af16-8a051bf0ae59
  Node              aks-storage-78891087-vmss000001 (46a4d6a7-71a8-4403-820b-16a8574bb45f)
  Health            online

Replicas:
  ID                8926e63e-952b-4668-8c1d-2d11e475ce1b
  Node              aks-storage-78891087-vmss000000 (a43882ae-647b-42fb-a460-cbdab2df4386)
  Health            ready
  Promotable        true
```

As demonstrated above, notice how only `pvc-replicated-centralised-topology` is in a `Bound` state and its volume name  `pvc-6ee17ec9-b845-409f-a00b-cb62f64aaca2` has `1` master volume and `1` replica volume which are located on node `aks-storage-78891087-vmss000001` and `aks-storage-78891087-vmss000000` respectively.
- The volumes have been successfully been provisioned on nodes which do not have the >> `storageos.com/computeonly=true` node label.

For `pvc-replicated-centralised-topology-test`, we can see that it is stuck in a `Pending` state, as the PVC definition - we used the label >> `storageos.com/replicas=3` which requests for `1` master volume and `3` replica volumes respectively. 
- This would mean that we require at least `4` nodes to provision the Ondat volume and its replicas - which is not possible as only `2` nodes are available to be used as storage nodes whilst the rest of the nodes are reserved for compute intensive tasks.