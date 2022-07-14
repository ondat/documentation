---
title: "Platform Upgrade"
linkTitle: "Platform Upgrade"
weight: 1
---

## Overview

This guide will demonstrate how to enable protection for your orchestrator's rolling upgrades using the [Upgrade Guard](/docs/concepts/rolling-upgrades/#upgrade-guard) and [Node Manager](/docs/concepts/rolling-upgrades/#node-manager). This feature helps prevent your persistent storage volumes from becoming unhealthy during the rolling downtime of an orchestrator upgrade.

> ⚠️ This feature is currently in tech preview, we only recommend using this feature on your test clusters.

## Prerequisites

> ⚠️ Make sure you have met the requirements of [configuring a Pod Disruption Budget (PDB)](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).

> ⚠️ If your volume does not have any replicas, the rolling upgrades feature will not start on any StorageOS node until you have one or more replicas on all your volumes.

> ⚠️ This feature supports the following platforms: Google Anthos, Google GKE with future support to be expanded to Amazon EKS, Openshift and Rancher.

> ⚠️ Using Ondat for the internal registry is not recommended. OpenShift requires the internal registry to be available but Ondat volumes may become unavailable during the upgrade.

> ⚠️ For Openshift: The PDB feature is only stable in kubernetes v1.21+ and Openshift v4.8+.

## Procedure

### Step 1 - Enable Node Manager & Upgrade Guard

* Add the following lines to the `StorageOSCluster` spec:

 ```yaml
  nodeManagerFeatures:
    upgradeGuard: ""
 ```

* Alternatively, you can run the following command:

 ```bash
 kubectl get storageoscluster -n storageos storageoscluster -o yaml | sed -e 's|^spec:$|spec:\n  nodeManagerFeatures:\n    upgradeGuard: ""|' | kubectl apply -f - 
 ```

* You will see new pods getting created, one pod per node in a cluster called Node Manager. If you enable upgrade guard during first installation, upgrade guard might fall into a temporary `CrashLoopBackoff` loop until all cluster components are up and running.

Upgrade Guard has a few configuration options:
* `MINIMUM_REPLICAS_FOR_UPGRADE`: minimum replica number of any volume. Default: 1
* `WATCH_ALL_VOLUMES`: watch all volume on every nodes, otherwise Upgrade Guard watches volumes and its replicas on the node where it is running. Extra safety option with performance impact. Default: false

 ```yaml
  nodeManagerFeatures:
    upgradeGuard: "MINIMUM_REPLICAS_FOR_UPGRADE=2,WATCH_ALL_VOLUMES=true"
 ```

### Step 2 - Rolling Upgrades Is Ready

Congratulations, you are now ready to start the rolling upgrade process of your orchestrator!

> ⚠️ GKE and AKS take care of the pod disruption budget for one hour. After this time period they drain the node, which would destroy the volume.

> ⚠️ EKS takes care on PDB for 50 mins, after this period upgrade would fail unless it was forced.
