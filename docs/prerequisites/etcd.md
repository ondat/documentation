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

For production environments we recommend backing etcd with EBS volumes. This allows the etcd operator to recover from node failures.

TODO: explain how to setup an EBS csi driver

For testing environments a node-local storage option can be used, such as [Local Path Provisioner](https://github.com/rancher/local-path-provisioner). This will store etcd data on the node hosting an etcd pod 

> ⚠️ The `local-path` StorageClass is only recommended for **non production** clusters, as this stores all the data of the `etcd` peers locally, which makes it susceptible to state being lost on node failures.


## Installing Etcd


An etcd cluster can be created in three different ways:
* Installing the etcd operator via our helm chart
* Installing Ondat (and the etcd operator) via our Plugin
* Manually applying an `etcdcluster` custom resource 

### Recommended: Installing the etcd operator via our helm chart:
For full instructions, visit [here](https://github.com/ondat/charts/tree/main/charts/ondat)


### Recommended: Installing Ondat (and the etcd operator) via our Plugin:
`kubectl storageos install --include-etcd --etcd-storage-class <the storage class you want to use for etcd> --etcd-tls-enabled`

### Manually applying an `etcdcluster` custom resource: 
This installation method allows the most configuration of the etcd cluster, but is the most error prone. 

Find the verison of the etcd operator you want to install from [Github](https://github.com/storageos/etcd-cluster-operator/releases/)

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

TODO:


## Etcd on External Virtual Machines

This [page](/docs/prerequisites/etcd-outside-k8s/etcd-outside-the-cluster.md) documents the process for installing etcd outside the Kubernetes cluster    
