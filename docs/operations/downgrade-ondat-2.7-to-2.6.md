---
title: "How To Downgrade Ondat from 'v2.7.0' to 'v2.6.0'"
linkTitle: "How To Downgrade Ondat from 'v2.7.0' to 'v2.6.0'"
---

## Overview

This guide will walk you through how to downgrade from Ondat `v2.7.0` to `v2.6.0`. This procedure can be used if a cluster administrator is required to roll back to the previous version after upgrading to Ondat `v2.7.0`.
- As part of the `v2.7.0` release, the Ondat team implemented a new architectural design for mapping Kubernetes volumes to the underlying data storage containers on disk. This will conduct a one-time step change to upgrade the deployment blob files and their metadata to the new format.
	- In the past, Ondat supported different container orchestrators, which required Ondat to use an internal UUID reference for these blob files. As Ondat now focuses only Kubernetes distributions (including OpenShift), the Ondat team have removed this abstraction layer and the naming will reflect the Kubernetes objects.
- As part of any operational upgrade plans, the Ondat team have provided guidance and steps in this document, should you need to roll back in case you experience any issues. 
- The procedure below has been validated, however it is not a common operation, therefore it is recommended that cluster administrators proactively reach out the Ondat Support Team by [creating a support ticket](/docs/support/) and get assistance from the Customer Success team, as you conduct the downgrade.

## Prerequisites

- Ensure that all of your stateful workloads using Ondat volumes are scaled down to zero.
- While the procedure is safe, it is strongly recommended that a backup of important stateful workloads done before performing the downgrade.

## Procedure

###  Step 1 - Uninstall Ondat `v2.7.0` - As If You Are Conducting An Upgrade

1. Delete the `storageoscluster` Custom Resource.
1. Delete the Ondat Operator deployment.
1. Ensure that you do not make any changes to Ondat's etcd cluster.

### Step 2 - Download & Update the `CLI_TOOL` Variable In The Downgrade Script

- Download the downgrade script and ensure that the [`CLI_TOOL` variable](https://github.com/ondat/documentation/blob/main/sh/downgrade-db-2-7-to-2-6.sh#L5-L6) in the downgrade script is using the correct CLI utility for your distribution.
  - The default value is `kubectl` which is used to interact with Kubernetes distributions. If your cluster is  and OpenShift distribution, ensure that you use `oc` as the CLI utility.

```bash
# Download the downgrade script.
curl -sO https://github.com/ondat/documentation/blob/main/sh/downgrade-db-2-7-to-2-6.sh

# edit and apply changes to the CLI_TOOL` according toif necessary.
vim downgrade-db-2-7-to-2-6.sh
```

### Step 3 - Run The Downgrade Script Against Your Cluster

> 💡 The downgrade script is idempotent, so in the case of interruption it can be safely run multiple times.

- Run the downgrade script against your Kubernetes or OpenShift cluster that has Ondat `v2.7.0` installed. The script will create a [Kubernetes daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) which will downgrade the internal data store on each node where Ondat is running. Once the downgrade is complete, the daemonset will be deleted.

```bash
# run the downgrade script.
./downgrade-db-2-7-to-2-6.sh
```

### Step 4 - Install Ondat `v2.6.0`

- Once the downgrade has completed, the next step will be to install Ondat v2.6.0 into your OpenShift or Kubernetes cluster.
	- For guides on how to install Ondat, review the [Install](/docs/install/) documentation.
