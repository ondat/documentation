---
title: "Ondat Files"
linkTitle: "Ondat Files"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.3.0` or greater.

### What Is Ondat Files?

Ondat provides support for [ReadWriteMany (RWX)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) persistent volumes.
- A RWX PVC can be used simultaneously by many Pods in the same Kubernetes namespace for read and write operations.
- Ondat RWX persistent volumes are based on a [shared filesystem](https://en.wikipedia.org/wiki/Clustered_file_system), the protocol being used for this feature's backend is [Network Files System (NFS)](https://en.wikipedia.org/wiki/Network_File_System).

### Ondat Files Architecture

For each RWX persistent volume, the following components below are required:

1. **Ondat ReadWriteOnly (RWO) Volume**
    - Ondat provisions a standard [volume](/docs/concepts/volumes) that provides a block device for the file system of the NFS server. 
    - This means that every RWX Volume has its own RWO Volume - thus allowing RWX Volumes to leverage the synchronous [replication](https://en.wikipedia.org/wiki/Replication_%28computing%29) and automatic [failover](https://en.wikipedia.org/wiki/Failover) functionality of Ondat, providing the NFS server with high availability.
1. **NFS-Ganesha Server**
    - For each RWX volume, an [NFS-Ganesha](https://nfs-ganesha.github.io/) server is spawned by Ondat.
    - The NFS server runs in user space on the bode containing the primary volume. Each NFS server uses its own *RWO* volume to store data so the data of each Volume is isolated.
    - Ondat binds an [ephemeral port](https://en.wikipedia.org/wiki/Ephemeral_port) to the host network interface for each NFS-Ganesha server. 
    - The NFS export is presented using [`NFS v4.2`](https://datatracker.ietf.org/doc/html/rfc7862). Ensure that you review the official [prerequisites](/docs/prerequisites/firewalls) page for more information on the port number range, that is for Ondat RWX persistent volumes to successfully run.
1. **Ondat API Manager**
    - The Ondat API Manager resource monitors Ondat RWX volumes to create and maintain a [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/) that points towards each RWX volume's NFS export endpoint. 
    - The API Manager is responsible for updating the service endpoint when a RWX volume failover occurs.

### How are Ondat ReadWriteMany (RWX) PersistentVolumeClaims (PVCs) Provisioned?

The sequence in which a RWX PVC is provisioned and used demonstrated in the steps below:

1. A `PersistentVolumeClaim` (PVC) is created with `ReadWriteMany` (RWX) access mode using any Ondat `StorageClass`.
1. Ondat dynamically provisions the `PersistentVolume` (PV).
1. A new Ondat `ReadWriteOnly` (RWO) Volume is provisioned internally (not visible in Kubernetes).
1. When the RWX PVC is consumed by a pod, an NFS-Ganesha server is instantiated on the same node as the primary volume.
	1. The NFS-Ganesha server then uses the RWO Ondat volume as its backend disk.
1. The *Ondat API Manager* publishes the host IP and port for the NFS service endpoint, by creating a Kubernetes service that points to the NFS-Ganesha server export endpoint.
1. Ondat issues a NFS mount on the Node where the Pod using the PVC is scheduled.

For more information on how to get started with Ondat Files, review the [ReadWriteMany (RWX)](/docs/operations/rwx) operations page.

### High Availability For Ondat Files

Ondat RWX volumes failover in the same way as standard Ondat RWO volumes. 
- The replica volume is promoted upon detection of node failure and the NFS-Ganesha server is started on the node containing the promoted replica. 
- The Ondat API Manager updates the endpoint of the Volume's NFS service, causing traffic to be routed to the URL of the new NFS-Ganesha server. 
- The NFS client in the application node (where the user's pod is running) automatically reconnects.

## Further Information

- All [Ondat Feature Labels](/docs/concepts/labels/) that work on RWO volumes will also work on RWX volumes.
- A Ondat RWX volume is matched one-to-one with a PVC. Therefore the Ondat RWX volume can only be accessed by pods in the **same** Kubernetes namespace.
- Ondat RWX volumes support volume resize.
	- For more information on how to resize a volume, review the [Volume Resize](/docs/operations/resize) operations page.
