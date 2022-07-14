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

> ⚠️ This feature supports the following platforms: Google Anthos, and Google GKE with future support to be expanded to Amazon EKS, Openshift, and Rancher.

> ⚠️ Using Ondat for the internal registry is not recommended. OpenShift requires the internal registry to be available but Ondat volumes may become unavailable during the upgrade.

> ⚠️ For Openshift: The PDB feature is only stable in Kubernetes v1.21+ and Openshift v4.8+.

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

* You will see new pods getting created, one pod per node in a cluster called Node Manager. If you enable the Upgrade Guard during the first installation, Upgrade Guard might fall into a temporary `CrashLoopBackoff` loop until all cluster components are up and running.

Upgrade Guard has a few configuration options:

* `MINIMUM_REPLICAS_FOR_UPGRADE`: minimum replica number of any volume, to allow an upgrade. Default: 1
* `WATCH_ALL_VOLUMES`: watch all volumes on every node, otherwise Upgrade Guard watches volumes and their replicas on the node where it is running. Extra safety option with a performance impact. Default: false

 ```yaml
  nodeManagerFeatures:
    upgradeGuard: "MINIMUM_REPLICAS_FOR_UPGRADE=2,WATCH_ALL_VOLUMES=true"
 ```

### Step 2 - Rolling Upgrades Is Ready

Congratulations, you are now ready to start the rolling upgrade process of your orchestrator!

> ⚠️ GKE and AKS take care of the pod disruption budget for one hour. After this period, they drain the node, which would destroy the volume.

> ⚠️ EKS takes care of PDB for 50 mins, after this period upgrade would fail unless it was forced.

> ⚠️ Upgrade Guard has a one-day termination period by default. The final termination period heavily depends on the platform you use. During the termination period, you should SSH into the node to create a backup in the worst-case scenario.

## Troubleshooting

* Volumes are healthy, all in sync but `storageos-node-manager` pod is hanging on the `Terminating` state.

The long termination period of Node Manager tries to keep failed node - and volumes on it - up and running as long as possible. This gives a chance to create a backup from an accidentally deleted machine. In case, Upgrade Guard isn't able to determine volume statuses, because of a network issue or missing StorageOS service, you have to delete pod manually by executing the following command:

```bash
kubectl delete pods -n storageos storageos-node-manager-XYZ --grace-period=0 --force
```

* A node has been removed accidentally or not in the official `graceful termination` way before drain, and two Node Manager pods - one in `Pending` and the other in `Terminating` states - are hanging on the same node.

Node Manager deployment tolerates almost every issue on the target node to protect your data. On the other hand, Node Manager doesn't tolerate itself on the same node. If a node goes down before Kubernetes was able to properly delete StorageOS Node daemonset, after the termination phase it re-schedules Node Manager pod to ensure the right number of replicas. But the pod isn't able to be scheduled, because of the toleration. Meantime Kubernetes isn't able to remove the pod in `Terminating` state, because Kubelet isn't responding.

The only way to solve this situation is to delete the node from Kubernetes cluster by executing the command below:

```bash
kubectl delete node XYZ
```

> ⚠️ Kubernetes has introduced Non-Graceful Node Shutdown Alpha in 1.24. This new feature allows cluster admins to mark failing nodes as `NoExecute` or `NoScedule`. Both options should solve the scheduling issue of Node Manager pod by decreasing the number of daemonset instances to the right number at Kubernetes API level, but in the absence of Kubelet termination of pods would still hangin.
