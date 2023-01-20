---
title: "Ondat Cloning"
linkTitle: "Ondat Cloning"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.10.0` or greater.

The Ondat Cloning feature adds support for specifying existing PVCs in the dataSource field to indicate a user would like to clone a volume.

### What is a Clone?

A clone is a duplicate of an existing Kubernetes volume that is its own unique volume on the system and can be consumed as any standard volume would be. However, with a clone, the data from a separate source is duplicated to the destination (clone). A clone is similar to a snapshot in that it's a point in time copy of a volume, however rather than creating a new snapshot object from a volume, we're instead creating a new independent volume, sometimes thought of as pre-populating the newly created volume.

### Why use Cloning

TODO.

### How Does It Work?

The Kubernetes [Volume Cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/) feature provides users with a mechanism to create a clone volume from an existing source volume.

For more information, see [How to Clone a Volume](/docs/operations/how-to-clone-a-volume).

### Current Scope & Limitations

The Ondat Cloning feature has the following limitations:

1. Cloning volumes across namespaces is not supported.
1. A clone volume must be the same size as the source volume which it is attempting to clone.
1. A clone volume must have the same filesystem as the source volume which it is attempting to clone.
