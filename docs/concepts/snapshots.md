---
title: "Ondat Snapshots"
linkTitle: "Ondat Snapshots"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.8.0` or greater.

The Ondat Snapshot feature can be used in conjunction with [Kasten K10](https://www.kasten.io/product/) to snapshot, backup and restore Kubernetes applications.

The snapshot functionality is useful for:

1. Disaster Recovery (DR) scenarios.
1. Rolling back unwanted changes.
1. Auditing purposes.
1. Migrating applications between clusters.

### What Are Snapshots, Backups & Restores?

A “**snapshot**” is a point-in-time copy of a PVC. Snapshots are modelled via the `VolumeSnapshot` and `VolumeSnapshotContent` Kubernetes API objects.
- Snapshots have limited use as they live within the cluster and cannot be used to restore the PVC if the node holding the snapshot is lost.

A “**backup**” is the process of materialising a new PVC, whose data source is a previously created snapshot and then extracting the data to a location outside of the cluster. 
- The Ondat Snapshots feature integrates with Kasten K10 to provide backup functionality.

A “**restore**” is the process of restoring an application from a given backup.
- The Ondat Snapshots feature integrates with Kasten K10 to provide restore functionality.

### How Does It Work?

The Kubernetes [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) feature provides users with a set of custom resource definitions (CRD) and APIs to create and manage volume snapshots. Storage providers can then implement the necessary [Container Storage Interface (CSI)](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/) APIs to integrate with this feature. 

This is exactly what we’ve done at Ondat. Additional backup tooling, like Kasten K10, can then be utilised to orchestrate and automate snapshotting, backups and restores.

To get started with installing and configuring the Ondat Snapshot feature in your Ondat cluster with Kasten K10, review the [Snapshots](/docs/operations/backups-and-restores-with-kastenk10/) operations page for more information.

> ⚠️ The Ondat Snapshots feature is not fully CSI compliant yet. As of today, the feature can only be used with Kasten K10 and with restoration from an external backup.

### Current Scope & Limitations

The Ondat Snapshots feature has the following limitations:

1. The feature has been designed to work with **Kasten K10** only. This is not a fully CSI compliant implementation of the specification yet.
1. Restoring via Kasten 10 from a “local snapshot” is not supported with the Ondat Snapshot feature. Users may only restore applications using a Kasten K10
“External backup”.
1. Snapshotting [ReadWriteMany (RWX)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) volumes is not supported. This is because it is next to impossible to ensure that a NFS mounted volume is in a suitable state for snapshotting. 
    1. For RWX volumes, the user only has access to the filesystem on the NFS client. It is not possible to run [`fsfreeze`](https://man7.org/linux/man-pages/man8/fsfreeze.8.html) on this mount point -- NFS does not support it. Thus the user can not [quiesce](https://en.wikipedia.org/wiki/Quiesce) the filesystem and we can not take a "consistent" snapshot.
