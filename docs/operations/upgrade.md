---
title: "Upgrade Ondat"
linkTitle: Upgrade Ondat
---
# Overview
This document details procedures to upgrade Ondat.

# Update an Ondat v2 cluster

## Prerequisites

> ⚠️ Ensure that you have read the [PIDs prerequisite introduced in Ondat v2.3](/docs/prerequisites/pidlimits) and that you check the init container logs to ensure your environments PID limits are set correctly.

> 💡 Pull the new Ondat container image `storageos/node:v2.6.0` on the nodes beforehand so that the cluster spins up faster!

> 💡 Speak with our support team [here](/docs/support/) so we can assist you with your upgrade.

> ⚠️ If you are upgrading to 2.7.0, you will only be able to downgrade to 2.6.0 due to the mapping changes made in the Data Plane. For more details, please look at the [release notes](/docs/release-notes).


## Procedure

### Step 1 - Backup of all Ondat yaml files

* Make sure you keep a backup of all the Ondat yaml files.
* You can also backup the Statefulset yaml files to keep track of the replicas.

    ```bash
    kubectl get pod -n storageos-operator -o yaml > storageos_operator.yaml
    kubectl get storageoscluster -n storageos-operator -o yaml > storageos_cr.yaml
    kubectl get statefulset --all-namespaces > statefulset-sizes.yaml
    ```

### Step 2 - Generate yaml file to upgrade cluster

* Run the following command to generate the `storageos-config.yaml` file that is used to upgrade your cluster based on your current configuration

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

* Edit StorageOSCluster object in the `/tmp/storageos-config.yaml` file by removing all images in the image section and modify the `storageos/node` image to:

    ```
    images:
        nodeContainer: "storageos/node:v2.7.0"
    ```

### Step 3 - Scale Ondat volumes to 0

* Scale all stateful applications that use Ondat volumes to 0

### Step 4 - Run uninstall cluster command

* Run the following command:

    ```
    kubectl storageos upgrade --uninstall-stos-operator-namespace storageos-operator --stos-cluster-yaml /tmp/storageos-config.yaml --etcd-endpoints "<ETCD-IP1>:2379,<ETCD-IP2>:2379,<ETCD-IP3>:2379"
    ```

> 💡 The plugin uses the `--uninstall-stos-operator-namespace` argument because it uninstalls the cluster first and then reinstalls it with the new version.

* The ETCD Endpoints should correspond to the endpoints you have in the `.spec.kvBackend` section of StorageOS object in the `/tmp/storageos-config.yaml` file.

> 💡 If at any point something goes wrong with the upgrade process, backups of all the relevant Kubernetes manifests can be found in `~/.kube/storageos/`.

### Step 5 - Check for `RUNNING` states

* Run the following command to check that all the Ondat pods have entered the `RUNNING` state

    ```bash
    kubectl get pods -l app=storageos -A -w
    ```

### Step 6 - Scale your stateful applications back up

Congratulations, you now have the latest version of Ondat!
