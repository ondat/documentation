---
title: "How To Safely Shut Down & Start Up A Cluster"
linkTitle: "How To Safely Shut Down & Start Up A Cluster"
---

## Overview 

To completely power down an Ondat cluster, for example, when needing to support a machine hall power event, it is recommended to follow the procedure demonstrated in this operation page.
- The main reason for this is to place the cluster into a pseudo maintenance mode to prevent any automated recovery and failover of volumes. 
- As the graceful and non-graceful shutdown support in Kubernetes progress towards GA we intend to introduce an automated capability in a future release of Ondat to automate this workflow.

## Prerequisites

- Ensure that you have installed and configured [`kubectl`](https://kubernetes.io/docs/tasks/tools/) to communicate with your cluster.
- Ensure that you have the [Ondat CLI](/docs/reference/cli/) utility deployed and configured to communicate with your Ondat cluster.

## Procedure - Shut Down The Cluster

### Step 1 - Inspect The Cluster To Ensure That All Master Volumes Are Online & Replica Volumes Are In-sync

Using the Ondat CLI utility, run the command below to query all the master volumes and any replica volumes, and then check that the health status is either >> `online` for masters volumes and >> `ready` for replica volumes.
- Ensure that no volume has a health status of >> `offline` or >> `unknown`.

```bash
# Check and ensure that all volumes are "online" and "ready".
kubectl exec -ti $(kubectl get pods -n storageos -l app=storageos-cli -o=jsonpath='{.items[0].metadata.name}') -n storageos -- storageos describe volume -A | grep Health

  Health            online                                                              
  Health            ready                                                               
  Health            online                                                              
  Health            online                                                              
  Health            online                                                              
  Health            online                                                              
  Health            ready                                                               
  Health            online                                                              
  Health            ready                                                               
  Health            online
```

### Step 2 - Scale Down Application Workloads To Stop Disk I/O Operations

First we want to stop disk I/O workloads gracefully and flush all the data to disk. To achieve this, follow your standard Kubernetes workflow or run book for scaling workloads to zero. Below is  it will probably look something similar to:

```bash
# Scale down StatefulSets and Deployments to 0 replicas.
kubectl scale statefulset,deployment -n $NAMESPACE --all --replicas=0
```

At this point, there should be nothing running that is generating I/O operations to any Ondat volumes. This enables end users to move onto the next step of stopping Ondat. 
- Ondat needs to be stopped first before powering down your Kubernetes cluster, as Ondat is designed to create new replicas of data for volumes that are no longer available. To avoid Ondat from conducting its normal recovery actions as soon as Kubernetes start shutting down nodes, as this is a planned event. By scaling down the workloads and shutting down Ondat, this will freeze all the data in place and maintain the consistency.

> 💡 Nothing is being done to the backing data or metadata. All of this will be preserved with this process, but as with every procedure where systems are being powered on and off, it is always recommended that backups are taken as a precaution in case your hardware has an issue powering back on.

### Step 3 -  Backup The Ondat Cluster Custom Resource

To shut down the Ondat cluster, the first step is to remove the Ondat cluster custom resource. End users, can explore the Ondat cluster definition by examining the Custom Resource Definition >> `storageosclusters.storageos.com`.
- Before deleting this object, ensure that a copy of the definition YAML manifest is made, as this is going to be used in the restoration stage that will be described later. 
- To back up the YAML manifest, run the following command and ensure that the output backup file >> `stos-backup.yaml` is stored in a safe place (or even added to a configuration management system):

```bash
# Backup the Ondat cluster Custom Resource.
kubectl get -n storageos stos storageoscluster > ./stos-backup.yaml
```

> 💡 In the code snippet demonstrated above, if you have used a different name for the CRD, ensure that you update the command with the correct name for it to successfully run.

### Step 4 - Backup The `etcd` Cluster Custom Resource

For end users that are also self-hosting `etcd` in the cluster, a recommendation will be to also back up the `etcd` definition as well. 
- To back up the YAML manifest,  run the following command and ensure that the output backup file >> `stos-etcd-backup.yaml` is stored in a safe place (or even added to a configuration management system):

```bash
# Backup the etcd cluster Custom Resource.
kubectl get -n storageos-etcd etcdcluster storageos-etcd > ./stos-etcd-backup.yaml
```

### Step 5 - Delete The Ondat Cluster

Once Custom Resource definitions have been backed up, the next step will be to delete the Ondat cluster object. This will also delete the Ondat daemonset pods from all the nodes and, in effect, will be left with a static system which has all the data intact on the nodes - although the Ondat data plane and control plane are no longer running. 
- This means that any node power down actions will not result in any volume recovery or failover actions as desired.

```bash
# Delete the Ondat cluster object.
kubectl delete -n storageos stos storageoscluster
```

### Step 6 - Delete The Ondat `etcd` Cluster

After the Ondat cluster is successfully deleted, the next step will be to need to scale down the Ondat `etcd` cluster. This will delete the `etcd` cluster pods, but not the PVCs which contain the member information.

```bash
# Delete the Ondat etcd cluster object.
kubectl delete -n storageos-etcd etcdcluster storageos-etcd
```

### Step 7 - Shut Down The Kubernetes Nodes 

The next step will be to follow your Kubernetes distribution guidance on how to power down your cluster. This stage will probably be similar to the following Kubernetes documentation on How to [safely drain a node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/), however, it is recommended to follow the specific instructions provided by your Kubernetes distribution on this topic.

```bash
# Drain a Kubernetes node in your cluster.
kubectl drain $NODE

# SSH into the worker node and shut it down after the drain workflow is complete.
ssh -t user@$NODE 'sudo shutdown now'
```

The procedure will probably call for shutting down all the worker nodes first (usually these [can be done in parallel](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#draining-multiple-nodes-in-parallel)), and then the master nodes, which again can usually all be done in parallel.


## Procedure - Start Up The Cluster

To power on the cluster after a power down, restart the Kubernetes distribution, which should be as simple as powering on the [control plane components](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components) and then the worker nodes. After a certain period of time, the Kubernetes nodes should be in a ready state. Once the nodes are in the ready state, the next step will be to restore the Ondat cluster definition and scale up the workloads.

### Step 1 - Restore The Ondat `etcd` Cluster Custom Resource

To restore the Ondat `etcd` cluster, simply apply the YAML manifest file that was created in the previous procedure:

```bash
# Apply the etcd cluster Custom Resource that was previously backed up.
kubectl apply -f ./stos-etcd-backup.yaml
```

Once successfully applied, ensure that all the `ectd` pods are in a `Running` state and ready:

```bash
# Check and ensure that the "etcd" pods are "Running" successfully.
kubectl get pods -n storageos-etcd
```

###  Step 2 - Restore The Ondat Cluster Custom Resource

After all the `etcd` pods are in a `Running` statue and ready, restore the Ondat cluster by applying the other YAML manifest file that was created in the previous procedure:

```bash
# Apply the Ondat cluster Custom Resource that was previously backed up.
kubectl apply -f ./stos-backup.yaml
```

Once successfully applied, ensure that all the Ondat pods, including the Ondat daemonset pods, are in a `Running` state and ready:

```bash
# Check and ensure that the Ondat pods are "Running" successfully.
kubectl get pods -n storageos
```

### Step 3 - Check That the Ondat Master Volumes & Replicas Are Online & Ready

Once you have validated that the Ondat daemonset is up and running, you can query the master volumes and replica volumes to check they are all reporting that they are back online and ready:

Using the Ondat CLI utility, run the command below to query all the master volumes and any replica volumes, and then check that the health status is either >> `online` for masters volumes and >> `ready` for replica volumes.
- Ensure that no volume has a health status of >> `offline` or >> `unknown`.

```bash
# Check and ensure that all volumes are "online" and "ready".
kubectl exec -ti $(kubectl get pods -n storageos -l app=storageos-cli -o=jsonpath='{.items[0].metadata.name}') -n storageos -- storageos describe volume -A | grep Health

  Health            online                                                              
  Health            ready                                                               
  Health            online                                                              
  Health            online                                                              
  Health            online                                                              
  Health            online                                                              
  Health            ready                                                               
  Health            online                                                              
  Health            ready                                                               
  Health            online
```

### Step 4 -  Scale Up The Application Workloads To Resume I/O Operations

The last step is to scale up the workloads again to resume I/O operations. For example:

```bash
# Scale up the StatefulSets back up to their desired replica count.
kubectl scale statefulset -n mynamespace <statefulset-name> --replicas=1

# Scale up the Deployments back up to to their desired replica count.
kubectl scale deployment -n mynamespace <deployment-name> --replicas=1
```
