---
title: "Ondat Snapshots"
linkTitle: "Snapshots"
---

# Overview

Customers often require backups for disaster recovery, auditing purposes and various other scenarios. Ondat Snapshots aims to enable customers to back up their Ondat data outside of their Kubernetes clusters. In conjunction with a backup solution, this functionality helps to recover users’ Kubernetes stateful applications whenever they want.

> ⚠️ This feature is currently available on `2.8.0-beta` - if you would like to gain early access to the product, speak with our experts on hello@ondat.io.

# How does it work?

1. The Ondat Snapshots feature takes a snapshot of your volume (i.e. a point-in-time copy of a volume that lives within your cluster). The snapshot now lives within your cluster.
1. Ondat Snapshots integrates with backup solutions like [Kasten](https://www.kasten.io) to provide backup and restore of Kubernetes stateful applications. Our feature integrates fully with Kasten, which offers free workflows for backing up Kubernetes data (e.g. to an S3 bucket if you are using AWS).
1. Your volume is now backed up externally and can be retrieved and restored using Kasten.


