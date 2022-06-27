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

### Quick Install

TODO: 


### Installation Step by Step

TODO: 


### Installation Verification

TODO:


## Etcd on External Virtual Machines

This [page](/docs/prerequisites/etcd-outside-k8s/etcd-outside-the-cluster.md) documents the process for installing etcd outside the Kubernetes cluster    
