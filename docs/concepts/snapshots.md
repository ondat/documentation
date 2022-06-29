---
title: "Ondat Snapshots"
linkTitle: Ondat Snapshots
---

# Overview

The Ondat Snapshot feature can be used in conjunction with [Kasten
K10](https://www.kasten.io/) to snapshot, backup and restore Kubernetes
applications. This functionality is useful for:

1. Disaster recovery scenarios
1. Rolling back unwanted changes
1. Auditing purposes
1. Moving applications between clusters

# Prerequisites

To utilize the Ondat Snapshot feature the following prerequisites must be met:

1. Ondat v2.8.0 or later is installed in the cluster
1. Kasten K10 is installed in the cluster. See the Kasten 10 docs for the full list of
[prerequisites](https://docs.kasten.io/latest/install/requirements.html#).
Kasten supports Kubernetes versions up to 1.22.

# What are snapshots, backups and restores?

A “snapshot” is a point-in-time copy of a PVC. Snapshots are modeled via the
`VolumeSnapshot` and `VolumeSnapshotContent` Kubernetes API objects. Snapshots
have limited use as they live within the cluster and cannot be used to restore
the PVC if the node holding the snapshot is lost.

A “backup” is the process of materialising a new PVC, whose data source is a
previously created snapshot and then extracting the data to a location outside
of the cluster. The Ondat Snapshots feature integrates with Kasten K10 to
provide backup functionality.

A “restore” is the process of restoring an application from a given backup. The
Ondat Snapshots feature integrates with Kasten K10 to provide restore
functionality.

# How does it work?

The Kubernetes [Volume
Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
feature provides users with a set of custom resource definitions (CRD) and APIs
to create and manage volume snapshots. Storage providers can then implement the
necessary CSI APIs to integrate with this feature. This is exactly what we’ve
done at Ondat. Additional tools, like Kasten K10, can then be utilised to
orchestrate and automate snapshotting, backups and restores.

Please see the [Backups and restores with Kasten
K10](/docs/operations/backups-and-restores-with-kastenk10) for a full
walk through.

> ⚠️ The Ondat Snapshot feature is not fully CSI compliant. As such the feature
can only be used with Kasten K10 and with restoration from an external backup.

# Scope and limitations

The feature has the following limitations:

1. The feature has been designed to work with Kasten K10 only. This is not a
fully CSI compliant implementation of the spec.
1. Restoring via Kasten 10 from a “local snapshot” is not supported with the
Ondat Snapshot feature. Users may only restore applications using a Kasten K10
“External backup”.
1. Snapshotting RWX volumes is not supported. This is because it is next to
impossible to ensure that a NFS mounted volume is in a suitable state for
snapshotting. For RWX volumes, the user only has access to the filesystem on
the NFS client. It is not possible to run `fsfreeze` on this mountpoint - NFS
does not support it. Thus the user can not quiesce the filesystem and we can
not take a "consistent" snapshot.
