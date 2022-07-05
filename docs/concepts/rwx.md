---
title: "Ondat Files"
linkTitle: "Ondat Files"
weight: 1
---

> ⚠️ Ondat must have a licence applied to use RWX Volumes. RWX volumes are supported on all licence tiers, including our Community Edition licence. For more information, please visit [Licensing](/docs/operations/licensing/#types-of-licenses).

Ondat supports ReadWriteMany (RWX) [access
mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
Persistent Volumes. A RWX PVC can be used simultaneously by many Pods in the
same Kubernetes namespace for read and write operations.

Ondat RWX Volumes are based on a shared filesystem - in the case of our
implementation, this is NFS.

## Architecture

For each RWX Volume, the following components are involved:

**Ondat ReadWriteOnly (RWO) Volume**

Ondat provisions a standard [Volume](/docs/concepts/volumes) that provides
a block device for the file system of the NFS server. This
means that every RWX Volume has its own RWO Volume. This allows RWX Volumes to
leverage the synchronous replication and automatic failover functionality of
Ondat, providing the NFS server with high availability.

**NFS-Ganesha server**

For each RWX Volume, an NFS-Ganesha server is spawned by Ondat. The NFS
server runs in user space on the Node containing the primary Volume. Each NFS
server uses its own RWO Volume to store data so the data of each Volume is
isolated.

Ondat binds an ephemeral port to the host network interface for each
NFS-Ganesha server. The NFS export is presented using NFS v4.2. Check the
[prerequisites page](/docs/prerequisites/firewalls) to see the
range of ports needed for Ondat RWX Volumes.

**Ondat API Manager**

Ondat fully integrates with Kubernetes. The Ondat API Manager Pod
monitors Ondat RWX Volumes to create and maintain a Kubernetes Service
that points towards each RWX Volume's NFS export endpoint. The API Manager is
responsible for updating the Service endpoint when a RWX Volume failover
occurs.

## Provisioning and using RWX PVCs

The sequence in which a RWX PVC is provisioned and used is as follows:

1. A PersistentVolumeClaim (PVC) is created with RWX access mode using any
   Ondat StorageClass.
2. Ondat dynamically provisions the PV.
3. A new Ondat RWO Volume is provisioned internally (not visible in
   Kubernetes).
4. When the RWX PVC is consumed by a pod, an NFS-Ganesha server is instantiated
   on the same Node as the primary Volume. The NFS-Ganesha server thus uses the
   RWO Ondat Volume as its backend disk.
5. The Ondat API Manager publishes the host IP and port for the NFS service
   endpoint, by creating a Kubernetes Service that points to the NFS-Ganesha
   server export endpoint.
6. Ondat issues a NFS mount on the Node where the Pod using the PVC is
   scheduled.

## High availability

RWX Volumes failover in the same way as standard RWO Ondat Volumes. The
replica Volume is promoted upon detection of Node failure and the NFS-Ganesha
server is started on the Node containing the promoted replica. The Ondat
API Manager updates the endpoint of the Volume's NFS service, causing traffic
to be routed to the URL of the new NFS-Ganesha server. The NFS client in the
application Node (where the user's Pod is running) automatically reconnects.

## Notes

- All feature labels that work on RWO Volumes will also work on RWX Volumes.
- A Ondat RWX Volume is matched one-to-one with a PVC. Therefore the
  Ondat RWX Volume can only be accessed by Pods in the same Kubernetes
  namespace.
- Ondat RWX Volumes support volume resize. Refer to the [resize](/docs/operations/resize)
documentation for more details.
