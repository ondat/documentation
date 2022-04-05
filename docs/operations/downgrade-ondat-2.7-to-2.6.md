---
title: "Downgrade Ondat from 2.7.0 to 2.6.0"
linkTitle: Downgrade Ondat from 2.7.0 to 2.6.0
weight: 150
---

# Overview

This guide will walk you through how to downgrade from Ondat v2.7.0 to v2.6.0. You can use this procedure should you decide that you need to roll back after upgrading to 2.7.0.

As part of the 2.7.0 release we are implementing a new design for mapping your Kubernetes volumes to the underlying data storage containers on disk. There will be a one time step to upgrade the deployment blob files and their metadata to the new format.

As part of any operational upgrade plans, we want to provide simple steps should you need to roll back in case of issues. The procedure below has been validated, however please do raise a proactive case [here](/docs/support/) ahead of any upgrades and work with the customer success teams as part of any upgrade process.
For those curious, in the past Ondat supported other Container Orchestrators (CO) and therefore used an internal UUID reference for these blob files. With the focus on only K8s now, we are removing this abstraction layer and the naming will reflect the K8s objects.

# Prerequisites

> ⚠️ Make sure all workloads using Ondat volumes are scaled down to zero.

> ⚠️ Recommended: While the procedure is safe, it is recommended that a backup of important stateful application is kept before performing the downgrade.

> ⚠️ Update the CLI_TOOL variable if you do not have access to kubectl.

> 💡 The tool is idempotent so in the case of interruption it can be safely run multiple times.

# Procedure

## Step 1 - Uninstall Ondat v2.7.0, as if you are starting an upgrade

1. Delete your storageoscluster CR
1. Delete your storageos operator deployment
1. Make sure to leave your Ondat etcd alone

## Step 2 - Run our downgrade script

1. Download the following script and edit it to match your cluster's specifications.

    ```
    curl -s https://docs.ondat.io/v2.7/sh/downgrade-db-2-7-to-2-6.sh
    ```

1. Run the script below:

    ```
    ./downgrade-db-2-7-to-2-6.sh
    ```

This will create a DaemonSet to downgrade our internal data store on each of your nodes. The Daemonset will delete itself afterwards.

## Step 3 - Install Ondat v2.6.0

You will now be able to use Ondat v2.6.0.
