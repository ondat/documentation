---
title: "Supported File System"
linkTitle: Supported File Systems
---

## Host Filesystems

Ondat will automatically use `/var/lib/storageos` on each host as a base
directory for storing [configuration and blob files](/docs/concepts/volumes#blob-files). 
Supported host filesystem types
are `ext4` and `xfs`. If you require a specific filesystem, [contact
Ondat](/docs/support/contactus).

## Persistent Volume Filesystems

Ondat provides a block device on which a file system can be created. The
creation of the filesystem is either handled by Ondat or by Kubernetes
which affects what filesystems can be created.

### CSI Driver

When using Ondat with the CSI driver, Ondat is responsible for running
mkfs against the block device that pods mount. Ondat is able to create
ext2, ext3, ext4 and xfs file systems.

