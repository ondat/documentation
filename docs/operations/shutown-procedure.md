---
title: "Shutdown procedure for an Ondat cluster"
linkTitle: "How To safely shutdown a cluster hosting Ondat storage"
---

# Shutdown Procedure for total cluster power down

To completely power down a cluster, for example when needing to support a machine hall power event, the following procedure should be followed. The main reason for this is to place the cluster into a pseudo Maintenance Mode to prevent any automated recovery and failover of volumes. As the graceful and non-graceful shutdown support in kubernetes progress towards GA we intend to introduce an automated capability in a future release of Ondat to automate this.

## Inspect your cluster to check that all volumes are online and all replicas are in-sync

Using the Ondat command-line, query all of the volumes and any replicas and check that the health of these is `online` for masters and `ready` for replicas, make sure nothing has a status of `offline` or `unknown`. For example:

```bash
kubectl exec -ti $(kubectl get pods -n storageos -l app=storageos-cli -o=jsonpath='{.items[0].metadata.name}') -n storageos -- storageos describe volume -A |grep Health
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

## Scale down application workloads to stop disk IO

First we want to stop disk I/O workloads gracefully and flush all the data to disk. To do this follow your standard kubernetes workflow or run book for scaling workloads to zero, it will probably look something similar to:

```bash
kubectl scale statefulset,deployment -n mynamespace --all --replicas=0
```

At this point, there should be nothing running that is generating I/O to any Ondat volumes and we are ready to stop Ondat. We need to stop Ondat before powering down kubernetes, as Ondat is designed to create new replicas of data for volumes that are no longer available. We do not want Ondat to do it's normal recovery actions as soon as we start shuting down nodes as this is a planned event. By scaling down the workloads and shutting down Ondat we will freeze all of the data in place and maintain the consistency.

**Note** We are not doing anything to the backing data or metadata. All of this will be preserved with this process, but as with every procedure where systems are being powered on and off, we would always recommend that backups are taken as a precaution in case hardware has an issue powering back on.

## Backup the Storage OS Cluster Custom Resource

To shutdown the Ondat cluster, we are going to remove the Ondat kubernetes custom resource. You can explore the Ondat cluster definition if you examine the Custom Resource Definition `storageosclusters.storageos.com`. Before we delete this object, we need to make a copy of the definition `yaml` as we are going to restore this as part of the cluster power on procedure. To backup the data run the following and then make sure the ouput backup file is in a safe place (or even added to a configuration management system):

```bash
kubectl get -n storageos stos storageoscluster > ./stos-backup.yaml
```

**Note** the above is based  on the default name, if you have used a different name please update the command as necessary.

## Backup the ETCD Cluster Custom Resource

If you are also self-hosting etcd in your cluster, then we will also backup the etcd definition as well. To do this run the following and make sure the backup file is in a safe place (or even added to configuration management system):

```bash
kubectl get -n storageos-etcd etcdcluster storageos-etcd > ./stos-etcd-backup.yaml
```

## Delete the Ondat cluster

Once we have backed up the kubernetes definitions, we are ready to delete the Ondat cluster object. This will also delete the daemon set from all of the nodes and in effect we will be left with a static system which has all of the data intact on the nodes, but the dataplane and controlplane for Ondat are no longer running. This means that any node power down actions will not result in any volume recovery or failover actions as desired.

```bash
kubectl delete -n storageos stos storageoscluster
```

## Delete the Ondat ETCD cluster

After the Ondat cluster is deleted, we need to scale down the Ondat ETCD cluster as well. This will delete the ETCD cluster pods, but not the PVCs which contain the member information.

```bash
kubectl delete -n storageos-etcd etcdcluster storageos-etcd
```

## Power off the nodes

Now follow your kubernetes platforms procedure for powering down the cluster, it will probably be similar to the following, however please do follow the specific instructions for your kubernetes distribution:

```bash
kubectl drain <node name>
ssh -t user@<node name> 'sudo shutdown now'
```

The procedure will probably call for shutting down all of the worker nodes first (usually these can be done in parallel), and then the master nodes which again can usually all be done in parallel.

# Power on procedure

To power on the cluster after a power down, we are going to restart the kubernetes platform which should be as simple as powering on the control plane and then the worker nodes. After a period of time we expect the kubernetes nodes to be in a ready state. Once the nodes are in the ready state we can restore the Ondat cluster definition and scale up the workloads.

## Restore the Ondat ETCD cluster definition

To restore the Ondat ETCD cluster simply apply the yaml file we created as our backup procedure:

```bash
kubectl apply -f ./stos-etcd-backup.yaml
```

## Check Ondat ETCD pods

Make sure that all of the ETCD pods are running and ready:

```bash
kubectl get pods -n storageos-etcd
```

## Restore cluster definition

After all the ETCD pods have become ready, restore the Ondat cluster by applying the other yaml file we created as our backup procedure:

```bash
kubectl apply -f ./stos-backup.yaml
```

Where in this case we have the backup yaml file in the local directory where we are running `kubectl` from.

## Check Ondat volumes and cluster

First check that the Ondat node daemon set has started up and all of the pods are running:

```bash
kubectl get pods -n storageos
```

All of the pods should be in the `running` state and healthy.

Once you have validated that the daemon set is up and running, you can query the volumes and replicas again to check they are all reporting correctly:

Using the Ondat command-line query all of the volumes and any replicas and check that the health of these is `online` for masters and `ready` for replicas, make sure nothing has a status of `offline` or `unknown`. For example:

```bash
kubectl exec -ti $(kubectl get pods -n storageos -l app=storageos-cli -o=jsonpath='{.items[0].metadata.name}') -n storageos -- storageos describe volume -A |grep Health
```

## Scale up workloads

The last step is to scale up the workloads again, e.g.

```bash
kubectl scale statefulset -n mynamespace <statefulset-name> --replicas=1
kubectl scale deployment -n mynamespace <deployment-name> --replicas=1
```

Where the number of replicas is appropriate for the application.
