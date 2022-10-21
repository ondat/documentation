---
title: "Ondat Storage Pooling"
linkTitle: "Ondat Storage Pooling"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.9.0` or greater.

Storage Pooling enables greater control over the type of storage a workload will use, this can be used to improve performance for resource-intensive applications and to reduce cost for less resource-intensive applications.

### What is Ondat Storage Pooling?

In short, storage pooling allows applications to target which drives they want to write data to.

The Storage Pooling feature allows creation of "Storage Pools", defined as a group of drives connected to a set of machines.

Applications can then use this storage pool, meaning any data written by the application will only be written to the drives in the storage pool

### Why use Storage Pooling

The main use-case for storage pooling is allowing heterogenous storage configurations in a cluster, without decreasing performance.

Without storage pooling Ondat will choose where to store data based on backend disk size and will spread data across all drives connected to a node (assuming the drive is mounted in `/var/lib/storageos/data/`). This means it is possible for a slow drive in the cluster to decrease the performance of a volume even if all the other drives in the cluster are very fast.

With storage pooling applications can be targeted to use specific drives. This means a resource-intensive application can be targeted to use high-performance NVMe drives, whilst less resource-intensive applications can be targeted against cheaper lower-performance drives.

### How to use Storage Pooling

Ondat installs a new custom resource definition (CRD) into the Kubernetes cluster, called a `Pool`.

Users can then create a `Pool`, specifying which drives and which nodes should be part of it.

An Ondat controller will then create a `StorageClass` for this pool. Any application that uses this `StorageClass` will then utilize only the drives in that `Pool`.

For detailed information on using Storage Pools  please review the [Storage Pooling](/docs/operations/pooling) operations page.
