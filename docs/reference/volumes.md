---
title: "Volumes"
linkTitle: Volumes
---

Ondat volumes are a logical construct which represent a writeable volume
and exhibit standard POSIX semantics. Ondat presents volumes as mounts into
containers via the Linux LIO subsystem.

Conceptually, Ondat volumes have a frontend presentation, which is what
the application sees, and a backend presentation, which is the actual on-disk
format. Depending on the configuration, frontend and backend components may be
on the same or different hosts.

Volumes are formatted using the linux standard ext4 filesystem by default.
Kubernetes users may change the default filesystem type to ext2, ext3, ext4, or
xfs by setting the fsType parameter in their StorageClass (see [Supported Filesystems](/docs/reference/filesystems#persistent-volume-filesystems) for more
information). Different filesystems may be supported in the future.

Ondat volumes are represented on disk in two parts. Actual volume data is
written to blob files in `/var/lib/storageos/data/dev[\d+]`. Inside these
directories, each Ondat block device gets two blob files of the form
`vol.xxxxxx.y.blob`, where x is the inode number for the device, and y is an
index between 0 and 1. We provide two blob files in order to ensure that
certain operations which require locking do not impede in-flight writes to the
volume.

In systems which have multiple `/var/lib/storageos/data/dev[\d+]` directories,
two blob files are created per block device. This allows us to load-balance
writes across multiple devices. In cases where dev directories are added after
a period of run time, later directories are favoured for writes until the data
is distributed evenly across the blob files.

Metadata is kept in directories named `/var/lib/storageos/data/db[\d+]`. We
maintain an index of all blocks written to the blob file inside the metadata
store, including checksums. These checksums allow us to detect bitrot, and
return errors on reads, rather than serve bad data. In future versions we may
implement recovery from replicas for volumes with one or more replicas defined.

Ondat metadata requires approximately 2.7GB of storage per 1TiB of allocated
blocks in the associated volume. This size is consistent irrespective of data
compression defined on the volume.

To ensure deterministic performance, individual Ondat volumes must fit on a single
node.

## Minimum Volume Size

The minimum volume size Ondat supports is 1GB.

## TRIM

Ondat volumes support TRIM/Unmap which allows the space allocated to
deleted blocks to be reclaimed from the backend blob files that back each
volume when a TRIM call is made. Support for TRIM is enabled by default for all
uncompressed volumes, volumes are created without compression enabled by
default. For more information on how to TRIM a filesystem, see [TRIM operations](/docs/operations/trim).

## Volume Resize

Ondat v2.1 supports offline resize of volumes. This means that a volume
cannot be resized while it is in use. Furthermore, in order for a resize
operation to take place the volume must not be attached to a node. This is to
ensure that the volume is not in use.

This means that if a Kubernetes pod is currently consuming a volume that a
resize request has been issued for, the resize will not be actioned until the
pod is terminated and the volume is detached from the node. The Ondat
controlplane will then attach the volume to the node that holds the master
deployment and resize the underlying block device and then run resize2fs to
expand the filesystem.

For a walkthrough of how to resize a volume, see the [Volume Resize](/docs/operations/resize) operations page.

## Volume Encryption

Volumes can be configured on creation to have encryption-at-rest. Data
is encrypted with XTS-AES and decrypted upon use. Please see
the [Encryption](/docs/features/encryption/) reference page for
more information.
