---
title: "Uninstall Ondat"
linkTitle: Uninstall Ondat
---

This document details a step-by-step procedure on how to remove Ondat from a
Kubernetes cluster.

Remember that Ondat enables the stateful applications within your cluster.
It's very important to remove any applications that rely on Ondat before
you remove Ondat itself, or those applications will suffer unrecoverable
errors.

## Removing Stateful Workloads and Data

1. Delete any resources using Ondat volumes

    Delete any statefulsets, deployments or pods that are using Ondat Volumes.

1. Delete PVCs using Ondat

    Delete any Persistent Volume Claims that are using Ondat.

    ```bash
    $ kubectl -n $NS delete pvc $PVC
    ```

    > ⚠️ **This will delete data held by Ondat and won't be recoverable.**

## Removing Ondat Cluster

1. Delete Ondat Cluster

    ```bash
    $ kubectl get storageoscluster --all-namespaces # Find the namespace where the Custom Resource runs
    $ kubectl -n $NS delete storageoscluster --all  # Usually to be found in storageos-operator
    ```
2. Wait until the Ondat resources are gone

    ```bash
    $ kubectl -n storageos get pod # NS: Namespace where Ondat Daemonset is running, usually 'storageos'
    ```
## Uninstalling the Ondat Operator

> ⚠️ **Delete the Cluster Operator once the Ondat Pods are terminated**
**The procedure is finished. Ondat is now uninstalled.**

## Removing Ondat contents and metadata (unrecoverable)

The steps up until now have been recoverable - as long as the etcd backing
Ondat and the contents of /var/lib/storageos on your nodes are safe then
Ondat can be reinstalled. For complete removal and recovery of disk space,
proceed as follows:

> ⚠️ **Warning: The following steps will delete all data held by Ondat and won't be
> recoverable.**

1. Remove the Ondat data directory

    You can choose between the following options for removing the Ondat data directory:

    1. (Option 1) Login in to the hosts and execute the following commands

        ```bash
        $ sudo rm -rf /var/lib/storageos
        $ sudo umount /var/lib/kubelet/plugins_registry/storageos
        ```

    1. (Option 2) Execute the following command to deploy a DaemonSet that removes the
       Ondat data directory.

        > ⚠️ ** This step is irreversible and once the data is removed it cannot
        > be recovered.**

        > Run the following command where `kubectl` is installed and with the
        > context set for your Kubernetes cluster.

        ```bash
        $ curl -s https://raw.githubusercontent.com/ondat/use-cases/main/scripts/permanently-delete-storageos-data.sh | bash
        ```

2. Flush Etcd Data

    > ⚠️ **This will remove any keys written by Ondat.**

    ```bash
    $ export ETCDCTL_API=3
    $ etcdctl --endpoints=http://$ETCD_IP:2379 del --prefix "storageos"
    ```

    If running Etcd with mTLS, you can set the certificates location with the
    following command.

    ```bash
    $ export ETCDCTL_API=3
    $ etcdctl --endpoints=https://$ETCD_IP:2379 \
            --cacert=/path/to/ca.pem          \
            --cert=/path/to/client-cert.pem   \
            --key=/path/to/client-key.pem     \
            del --prefix "storageos"
    ```
