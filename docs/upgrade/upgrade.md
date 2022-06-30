---
title: "Ondat Upgrade"
linkTitle: Ondat Upgrade
weight: 1
---
## Overview

This guide provides instructions on how to upgrade Ondat.

## Upgrading An Ondat `v2` Cluster

## Prerequisites

> ⚠️ Ensure that you have read the [PIDs prerequisite introduced in Ondat v2.3](/docs/prerequisites/pidlimits) and that you have checked the init container logs to ensure your environments PID limits are set correctly.

> 💡 Pull down the new Ondat container image `storageos/node:v2.8.0` onto the nodes beforehand so that the cluster spins up faster.

> 💡 Speak with our support team [here](/docs/support/) so we can assist you with your upgrade.

## Procedure

### Step 1 - Backup Ondat Deployment Manifests

* Make sure that you keep a backup of all the Ondat YAML files. You can also backup the `StatefulSet` yaml files to keep track of the replicas.

    ```bash
    kubectl get pod -n storageos -o yaml > storageos_operator.yaml
    kubectl get storageoscluster -n storageos -o yaml > storageos_cr.yaml
    kubectl get statefulset --all-namespaces > statefulset-sizes.yaml
    ```

### Step 2 - Scale Down Stateful Applications To Zero

* Scale all of the stateful applications that use Ondat volumes to 0.

### Step 3 - Upgrade Ondat

* Run the following command using the kubectl storageos plugin.

> Make sure you are using the latest version of the kubectl storageos plugin. You can make use of the [installation guide](/docs/reference/kubectl-plugin/) and get the latest version [here](https://github.com/storageos/kubectl-storageos).

    ```bash
    kubectl storageos upgrade
    ```

> 💡 Please use the `--etcd-tls-enabled` if using TLS with your ETCD.

> 💡 If you are using a namespace other than `storageos` for your Ondat install, please use `--uninstall-stos-operator-namespace` argument because it uninstalls the cluster first and then reinstalls it with the new version.

> 💡 If at any point something goes wrong with the upgrade process, backups of all the relevant Kubernetes manifests can be found in `~/.kube/storageos/`.

### Step 4 - Scale Up Stateful Applications

* Once the Ondat upgrade is complete and the core components are back online, scale up the stateful applications that use Ondat volumes back up to their respective replica count.
