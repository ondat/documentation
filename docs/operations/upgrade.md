---
title: "Upgrade Ondat"
linkTitle: Upgrade Ondat
---

This document details a step-by-step procedure to upgrade an Ondat v2 cluster.

Keep in mind that upgrading a cluster will require minor downtime of
applications using Ondat volumes. However we will take steps to minimize
the required downtime as much as possible.

> Ensure that you have read the [PIDs prerequisite introduced in Ondat
> v2.3](/docs/prerequisites/pidlimits) and that you check the
> init container logs to ensure your environments PID limits are set correctly.

> Warning: To reduce downtime, it is recommended to `docker pull` the new
> Ondat container image `storageos/node:< param latest_node_version >`
> on the nodes beforehand so that the cluster spins up faster!

1. Make sure you keep a backup of all the Ondat yaml files. You can also backup
   the Statefulset yaml files to keep track of the replicas.

    ```bash
    kubectl get pod -n storageos-operator -o yaml > storageos_operator.yaml
    kubectl get storageoscluster -n storageos-operator -o yaml > storageos_cr.yaml
    kubectl get statefulset --all-namespaces > statefulset-sizes.yaml
    ```

1. Then, generate the `storageos-config.yaml` file that is used to upgrade your
   cluster based on your current configuration by running the following
   commands:

    ```bash
    SECRET_NAME=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].spec.secretRefName}')
    SECRET_NAMESPACE=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].spec.secretRefNamespace}')
    kubectl get secret -n $SECRET_NAMESPACE $SECRET_NAME -oyaml > /tmp/storageos-config.yaml
    echo "---" >> /tmp/storageos-config.yaml
    STOS_NAME=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].metadata.name}')
    STOS_NAMESPACE=$(kubectl get storageoscluster -A -o=jsonpath='{.items[0].metadata.namespace}')
    kubectl get storageoscluster -n $STOS_NAMESPACE $STOS_NAME -oyaml >> /tmp/storageos-config.yaml
    ```
    This file will include the manifest of 2 Kubernetes objects, the
    authentication Secret object and the StorageOS CR object.

    Edit StorageOSCluster object in the `/tmp/storageos-config.yaml` file by
    removing all images in the image section and modify the `storageos/node`
    image to:
    ```
    images:
        nodeContainer: "storageos/node:< param latest_node_version >"
    ```

1. Scale all stateful applications that use Ondat volumes to 0.

1. Using the plugin, run the following command:
    ```
    kubectl storageos upgrade --uninstall-stos-operator-namespace storageos-operator --stos-cluster-yaml /tmp/storageos-config.yaml --etcd-endpoints "<ETCD-IP1>:2379,<ETCD-IP2>:2379,<ETCD-IP3>:2379"
    ```

    > The plugin uses the `--uninstall-stos-operator-namespace` argument
    > because it uninstalls the cluster first and then reinstalls it with the
    > new version.

    The ETCD Endpoints should correspond to the endpoints you have in the
    `.spec.kvBackend` section of StorageOS object in the
    `/tmp/storageos-config.yaml` file.

    > If at any point something goes wrong with the upgrade process, backups of all the relevant
    > Kubernetes manifests can be found in `~/.kube/storageos/`.

1. Wait for all the Ondat pods to enter the `RUNNING` state
    ```bash
    kubectl get pods -l app=storageos -A -w
    ```
1. Scale your stateful applications back up.

Congratulations, you now have the latest version of Ondat.
