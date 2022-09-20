---
title: "How To Check The Health Status Of Your Cluster"
linkTitle: "How To Check The Health Status Of Your Cluster"
---

## Overview

This guide demonstrates different methods on how to check and review the health status of your Ondat cluster. Below are two of the common methods on how to assess the health status of a cluster:

1. Through the [Ondat SaaS Platform](https://portal.ondat.io/).
1. Through the [Ondat CLI](/docs/reference/cli/)

## Prerequisites

- If you are using the Ondat SaaS platform, ensure that your cluster has been successfully registered.
- If you are using the Ondat CLI, ensure that you have successfully downloaded and configured the utility to communicate with your Ondat cluster.

## Procedure

### Option 1 - Check Cluster Health Status Through The Ondat SaaS Platform

1. Login to the **Ondat SaaS Platform** and navigate to the **Clusters** tab >> Click on **View Details** on the cluster that you would like to inspect further.

    ![Cluster Summary - Ondat SaaS Platform](/images/docs/operations/check-cluster-health-status/01-check-cluster-summary.png)

1. In the **Cluster Summary** tab, information about the Connection Status is provided. To review the health status of the nodes in the cluster, click on the **Nodes** tab for more information.

    ![Node Health Status - Ondat SaaS Platform](/images/docs/operations/check-cluster-health-status/02-check-node-health-status.png)

### Option 2 - Check Cluster Health Status Through The Ondat CLI

1. Deploy and run the [Ondat CLI utility as a deployment](https://docs.ondat.io/docs/reference/cli/#run-the-cli-as-a-deployment-in-your-cluster) first, so that you can interact and manage Ondat through `kubectl`. Once deployed, obtain the Ondat CLI utility pod name for later reference.

    ```bash
    # Get the pod name of the Ondat CLI utility.
    kubectl get pods --namespace storageos | grep "storageos-cli"

    storageos-cli-578c4f4674-7jwrj                       1/1     Running   0          70s
    ```

1. With the Ondat CLI now deployed, you can check the cluster health and nodes status:

    ```bash
    # Get the cluster-wide configuration and show the number of healthy nodes.
    kubectl --namespace=storageos exec storageos-cli-578c4f4674-7jwrj -- storageos get cluster

    ID:           a77e7536-03b9-4d39-98ad-031055c3a2e2
    Created at:   2022-09-13T14:25:20Z (4 hours ago)
    Updated at:   2022-09-13T14:25:20Z (4 hours ago)
    Nodes:        5
      Healthy:    5
      Unhealthy:  0

    # Get the number of nodes in your cluster and also show their health status.
    kubectl --namespace=storageos exec storageos-cli-578c4f4674-7jwrj -- storageos get nodes

    NAME                             HEALTH  AGE
    aks-default-33007487-vmss000002  online  4 hours ago
    aks-storage-34962329-vmss000001  online  4 hours ago
    aks-default-33007487-vmss000001  online  4 hours ago
    aks-storage-34962329-vmss000000  online  4 hours ago
    aks-default-33007487-vmss000000  online  4 hours ago
    ```
