---
title: "Etcd"
linkTitle: Etcd
weight: 600
---

Ondat requires an etcd cluster in order to function. For more information
on why etcd is required, see our [etcd concepts](/docs/concepts/etcd) page.

We do not support using the Kubernetes etcd for Ondat installations.

For most use-cases we recommend installing our etcd operator, which will manage creation and maintenance of Ondat's required etcd cluster.
In some circumstances it makes sense to install etcd on separate machines outside of your Kubernetes cluster.

## Installing Etcd Into Your Kubernetes Cluster

This is our recommended way to host etcd, in both testing and production environments.

## Configuring Storage for Etcd

We highly recommend using cloud provider network attached disks for storing etcd data, such as EBS volumes, Google Persistent Disks, Azure Disks, etc. This allows the etcd operator to recover from node failures.

For testing environments a node-local storage option can be used, such as [Local Path Provisioner](https://github.com/rancher/local-path-provisioner). This will store etcd data on the node hosting an etcd pod

> ⚠️ The `local-path` StorageClass is only recommended for **non production** clusters, as this stores all the data of the `etcd` peers locally, which makes it susceptible to state being lost on node failures.

### How to set up an EBS CSI Driver

In AWS, you can use EBS volumes to host the etcd PVCs. The Ondat etcd usage of disk depends on the size of the Kubernetes cluster. However, it is recommended that the disks have at least 800 IOPS at any point in time. The best cost effective storage class that fulfils such requirements is gp3. If gp2 is used, it is paramount to use a volume bigger than 256Gi as it will have enough IOPS even when the burstable credits are exhausted.

To use a gp3 storage class in Kubernetes it is required to install the Amazon CSI Driver. Follow [this guide](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) to install. The procedure is comprehended by the following steps:

* Create IAM permissions <https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html>
* Install the CSI driver
  * [Using EKS addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html)
  * [Using self-managed add on](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md) (AWS clusters, but not in EKS)

## Installing Etcd

An etcd cluster can be created in three different ways:

* Installing the etcd operator via our helm chart
* Installing Ondat (and the etcd operator) via our Plugin
* Manually deploying the etcd operator and applying an `etcdcluster` custom resource

### **Recommended:** Installing the etcd operator via our helm chart

For full instructions, visit [here](https://github.com/ondat/charts/tree/main/charts/ondat)

### **Recommended:** Installing Ondat (and the etcd operator) via our Plugin

`kubectl storageos install --include-etcd --etcd-storage-class <the storage class you want to use for etcd> --etcd-tls-enabled`

### **Configurable:** Manually applying an `etcdcluster` custom resource

This installation method allows the most configuration of the etcd cluster, but is the most error-prone.

* Manually applying an `etcdcluster` custom resource

### Recommended: Installing the etcd operator via our helm chart

For full instructions, visit [here](https://github.com/ondat/charts/tree/main/charts/ondat)

### Recommended: Installing Ondat (and the etcd operator) via our Plugin

`kubectl storageos install --include-etcd --etcd-storage-class <the storage class you want to use for etcd> --etcd-tls-enabled`

### Manually applying an `etcdcluster` custom resource

This installation method allows the most configuration of the etcd cluster, but is the most error-prone.

Find the verison of the etcd operator you want to install from [GitHub](https://github.com/storageos/etcd-cluster-operator/releases/)

Install the etcd operator:

```
export ETCD_OPERATOR_VERSION=<set the version you want to use>
kubectl apply -f https://github.com/storageos/etcd-cluster-operator/releases/download/${ETCD_OPERATOR_VERSION}/storageos-etcd-cluster-operator.yaml
```

Then adapt the following sample to your needs and use `kubectl` to  apply it:

```
export ETCD_OPERATOR_VERSION=<set the version you want to use>
wget https://github.com/storageos/etcd-cluster-operator/releases/download/${ETCD_OPERATOR_VERSION}/storageos-etcd-cluster.yaml
vim storageos-etcd-cluster.yaml
kubectl apply -f storageos-etcd-cluster.yaml
```

### Installation Verification

```
$ kubectl -n storageos-etcd get pod,svc,pdb
NAME                                                     READY   STATUS    RESTARTS   AGE
pod/storageos-etcd-0-28m5t                               1/1     Running   0          18h
pod/storageos-etcd-1-2lpn9                               1/1     Running   0          18h
pod/storageos-etcd-2-dpdz6                               1/1     Running   0          18h
pod/storageos-etcd-3-7lsmz                               1/1     Running   0          18h
pod/storageos-etcd-4-q5xjd                               1/1     Running   0          18h
pod/storageos-etcd-controller-manager-6f5776c64f-dhp7r   1/1     Running   0          18h
pod/storageos-etcd-controller-manager-6f5776c64f-vvxrr   1/1     Running   0          18h
pod/storageos-etcd-proxy-96bf4bb5f-z5m7f                 1/1     Running   0          18h

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/storageos-etcd         ClusterIP   None            <none>        2379/TCP,2380/TCP   18h
service/storageos-etcd-proxy   ClusterIP   10.43.199.194   <none>        80/TCP              18h

NAME                                        MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/storageos-etcd   3               N/A               2                     18h
```

## Etcd on External Virtual Machines

This [page](/docs/prerequisites/etcd-outside-k8s/etcd-outside-the-cluster) documents the process for installing etcd outside the Kubernetes cluster
