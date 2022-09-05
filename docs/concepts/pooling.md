---
title: "Ondat Storage Pooling"
linkTitle: "Ondat Storage Pooling"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.9.0` or greater.

Storage Pooling enables greater control over the type of storage a workload will use, this can be used to improve performance for storage-intensive applications and to reduce cost for less resource intensive applications.

### What is Ondat Storage Pooling?

The Storage Pooling feature allows creation of "Storage Pools", a Storage Pool is simply a group of drives connected to a set of machines.

Applications can then use this Storage Pool, meaning any data wrote by the application will only be written to the drives in the Storage Pool

In short storage pooling allows applications to target which drives they want to write data to.

### Why use Storage Pooling

The main use-case for storage pooling is allowing heterogenous storage configurations in a cluster, without decreasing performance.

Without storage pooling Ondat will choose where to store data based on backend disk size and will spread data across all drives connected to a node (assuming the drive is mounted in `/var/lib/storageos/data/`). This meant it was possible for a slow drive in the cluster to decrease the performance of a volume even if all the other drives in the cluster were very fast.

With storage pooling applications can be targeted to use specific drives. This means a storage-intensive application can be targeted to use high-performance NVMe drives, whilst less  resource intensive applications can be targeted against cheaper lower-performance drives.

### How it works

Ondat installs a new custom resource definition (CRD) into the Kubernetes cluster, called a `Pool`.

Users can then create a `Pool`, specifying which drives and which nodes should be part of it.

An Ondat controller will then create a `StorageClass` for this pool. Any application that uses this `StorageClass` will then utilize only the drives in that `Pool`.  

### How to use Storage Pooling

#### Preparing your Drives

#### Creating a Storage Pool

#### Using a Storage Pool

#### Updating a Storage Pool

#### Deleting a Storage Pool
