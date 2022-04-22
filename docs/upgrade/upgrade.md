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

> 💡 Pull down the new Ondat container image `storageos/node:v2.7.0` onto the nodes beforehand so that the cluster spins up faster.

> 💡 Speak with our support team [here](/docs/support/) so we can assist you with your upgrade.

> ⚠️ If you are upgrading to `v2.7.0`, you will only be able to downgrade to `v2.6.0` due to the mapping changes made in the Data Plane. For more information, review the [release notes](/docs/release-notes).

## Procedure

### Step 1 - Backup Ondat Deployment Manifests

* Make sure you keep a backup of all the Ondat YAML files. You can also backup the `StatefulSet` yaml files to keep track of the replicas.

    ```bash
    kubectl get pod -n storageos-operator -o yaml > storageos_operator.yaml
    kubectl get storageoscluster -n storageos-operator -o yaml > storageos_cr.yaml
    kubectl get statefulset --all-namespaces > statefulset-sizes.yaml
    ```

### Step 2 - Generate The `storageos-config.yaml` Manifest

* Run the following commands to generate the `storageos-config.yaml` file that is used to upgrade your cluster based on your current configuration.

    ```bash
    SECRET_NAME=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].spec.secretRefName}')
    SECRET_NAMESPACE=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].spec.secretRefNamespace}')
    kubectl get secret -n $SECRET_NAMESPACE $SECRET_NAME -oyaml > /tmp/storageos-config.yaml
    echo "---" >> /tmp/storageos-config.yaml
    STOS_NAME=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].metadata.name}')
    STOS_NAMESPACE=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].metadata.namespace}')
    kubectl get storageoscluster -n $STOS_NAMESPACE $STOS_NAME -oyaml >> /tmp/storageos-config.yaml
    ```

* This file will include the manifest of 2 Kubernetes objects, the authentication Secret object and the StorageOS CR object.

* Edit `StorageOSCluster` object in the `/tmp/storageos-config.yaml` file by removing all images in the image section and modify the `storageos/node` image to:

    ```yaml
    images:
        nodeContainer: "storageos/node:v2.7.0"
    ```

### Step 3 - Scale Down Stateful Applications To Zero

* Scale all of the stateful applications that use Ondat volumes to 0.

### Step 4 - Upgrade Ondat

* Run the following command to conduct the upgrade:

    ```bash
    kubectl storageos upgrade --uninstall-stos-operator-namespace storageos-operator --stos-cluster-yaml /tmp/storageos-config.yaml --etcd-endpoints "<ETCD-IP1>:2379,<ETCD-IP2>:2379,<ETCD-IP3>:2379"
    ```

> 💡 The plugin uses the `--uninstall-stos-operator-namespace` argument because it uninstalls the cluster first and then reinstalls it with the new version.

* The `etcd` endpoints should correspond to the endpoints you have in the `.spec.kvBackend` section of StorageOS object in the `/tmp/storageos-config.yaml` file.

> 💡 If at any point something goes wrong with the upgrade process, backups of all the relevant Kubernetes manifests can be found in `~/.kube/storageos/`.

### Step 5 - Verifying The Ondat Upgrade

* Run the following commands to inspect Ondat's resources are back online (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd
    ```

### Step 6 - Scale Up Stateful Applications

* Once the Ondat upgrade is complete and the core components are back online, scale up the stateful applications that use Ondat volumes back up to their respective replica count.
