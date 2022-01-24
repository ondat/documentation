---
title: "Kubernetes Object Sync"
linkTitle: Kubernetes Object Sync
---

The below controllers are part of the [Ondat API manager](/docs/concepts/components), and handle a variety of cases where
information about Kubernetes objects from your cluster needs to be synced to
your Ondat cluster.

The CSI Driver annotation mentioned below is added to your PVC or Node
automatically by Ondat and is not removed. It is set by default in the case
of a PVC [StorageClass](/docs/operations/storageclasses) or
PVC's StorageClassName parameter, or in the case of a node, by the node driver
registrar.

## PVC Label Sync

The PVC Label Sync Controller applies labels that have been added to your PVCs
to your [Ondat Volume objects](/docs/concepts/volumes). The
PVC must have the Ondat CSI Driver annotation. If there is a label with the
same key on the PVC and on the StorageClass the PVC label will take precedence.

Ondat dynamically provisions Ondat Volumes when you create a PVC
object. Labels are initially applied to your Ondat Volume object when it is
created. These come from the labels specified in the PVC manifest as well as
any default labels specified in the StorageClass.

This controller is triggered on any subsequent PVC label update event, so long
as the CSI Driver annotation is present.

If a label sync fails the change will be requeued and retried. A periodic
resync runs every hour (this is configurable via `-pvc-label-resync-interval`
flag for the [API Manager](https://github.com/storageos/api-manager)).

## Node Label Sync

The Node Label Sync controller ensures that labels applied to your Kubernetes
nodes are synced through to Ondat. It is necessary for your [Node](/docs/concepts/nodes) to have the Ondat CSI Driver annotation.

When labels are applied to your Kubernetes nodes, they do not automatically
sync to Ondat, hence this controller is required to automatically apply the
expected behaviour to your Ondat cluster.

It is triggered on any Kubernetes label update event, so long as the CSI Drive
annotation is present.

If a label sync fails the change will be requeued and retried. A periodic
resync runs every hour (this is configurable via `-node-label-resync-interval`
flag for the [API Manager](https://github.com/storageos/api-manager)).

## Node Delete

The Node Delete Controller syncs deletions from your Kubernetes cluster to
Ondat.

This controller dynamically removes nodes from your Ondat cluster, being
triggered when the Kubernetes node is removed. 

Whenever a node delete event occurs the Node Delete Controller will trigger if
the node has the Ondat CSI driver annotation.

If the node holds an Ondat Volume without a replica then it cannot be
deleted by this controller. The Volume must be deleted first and then the node.
This is to prevent data loss by accidental deletion of a master volume. 

A periodic garbage collection runs every hour (this is configurable via
`-node-delete-gc-interval` flag for the [API Manager](https://github.com/storageos/api-manager).

## Namespace Delete

The Namespace Delete Controller is responsible for removing Ondat
[namespaces](/docs/concepts/namespaces) from the Ondat
cluster when the corresponding Kubernetes namespace has been removed from
Kubernetes.

The Ondat controlplane automatically creates a new Ondat namespace when
a PVC is created in a Kubernetes namespace. Ondat does not automatically
remove namespaces when there are no volumes in them. Instead this controller
triggers on any Kubernetes namespace deletion event, syncing Kubernetes
namespace deletion to Ondat namespace deletion.

A periodic garbage collection runs every hour (this is configurable via
`-namespace-delete-gc-interval` flag for the [API Manager](https://github.com/storageos/api-manager).
