---
title: "Rancher Kubernetes Engine (RKE) via Marketplace"
linkTitle: "Rancher Kubernetes Engine (RKE) via Marketplace"
weight: 11
description: >
    Walkthough guide to install Ondat onto a Rancher Cluster via Marketplace
---

## Overview

This guide will demonstrate how to install Ondat onto a [Rancher Kubernetes Engine (RKE)](https://rancher.com/products/rke) cluster using either the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/) or [Helm Chart](https://helm.sh/docs/intro/install/)

## Prerequisites

### 1 - Cluster and Node Prerequisites

The minimum cluster requirements for a **non-production installation** of ondat are as follows:

* Linux with a 64-bit architecture
* 2 vCPU and 8GB of memory
* 3 worker nodes in the cluster and sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster
* Make sure your RKE cluster uses a Linux distribution that is officially supported by Rancher as your node operating system and has the required LinuxIO related kernel modules are available for Ondat to run successfully. A strong recommendation would be to review [SUSE Rancher Support Matrix](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/) documentation to ensure that you are using a supported Linux distribution.

For a comprehensive list of prerequisites and how to build a **production installation** of Ondat please refer to [Ondat Prerequisites](https://docs.ondat.io/docs/prerequisites/)

### 2 - Installing a Local Path Provisioner

By default, a newly provisioned RKE cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) and make it the default storageclass to provide local storage for Ondat's embedded `etcd` cluster operator deployment.

    ```bash  
    kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml"
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    ```

Verify that the Local Path Provisioner was successfully deployed and ensure that that the deployment is in a  `RUNNING` status, run the following `kubectl` commands.

    ```bash
    kubectl get pod --namespace=local-path-storage
    kubectl get storageclass
    ```

### 3 - Client Tools Prerequisites

The following CLI utilities are installed on your local machine and available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

Ondat can be installed either via Helm Chart or using our command-line tool.  Depending on which installation method you choose you will require either:

* [kubectl-storageos CLI](/docs/reference/kubectl-plugin/)
* [Helm 3 CLI](https://helm.sh/docs/intro/install/)

### Installing Ondat Using Rancher's Apps & Marketplace

#### Step 1 - Setup An etcd Cluster

* Ensure that you have an `etcd` cluster deployed first before installing Ondat through the Helm chart located on Apps & Marketplace. There are two different methods listed below with instructions on how to deploy an `etcd` cluster;

    1. [Embedded Deployment](https://docs.ondat.io/docs/prerequisites/etcd/#testing---installing-etcd-into-your-kubernetes-cluster) - deploy an `etcd` cluster operator into your RKE cluster, recommended for **non production** environments.
    1. [External Deployment](https://docs.ondat.io/docs/prerequisites/etcd/#production---etcd-on-external-virtual-machines) - deploy an `etcd` cluster in dedicated virtual machines, recommended for **production** environments.

* Once you have an `etcd` cluster up and running, ensure that you note down the list of `etcd` endpoints as comma-separated values that will be used when configuring Ondat in **Step 3**.
  * For example, `203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379`

#### Step 2 - Locate Ondat Operator Helm Chart

1. In the Rancher UI, under the RKE cluster where Ondat will be deployed - select the **Menu** button in the top-left corner of the page and then select **Apps & Marketplace**.
1. Under **Apps & Marketplace**, a **Charts** page will be displayed where you can locate the [Ondat Operator Helm chart](https://github.com/rancher/partner-charts/tree/main/charts/ondat-operator/ondat-operator) by searching for "**Ondat**" in the search filter box.
1. Once you have located the Ondat Operator Helm chart, select the chart. This will direct you to a page showing you more information about the Ondat Operator and how to install it.
1. Select the **Install** button.

#### Step 3 - Customising & Installing The Helm Chart

1. Upon selecting the **Install** button in the previous step, you will be directed to a page to configure the **Application Metadata**. Define the namespace and application name where Ondat will be deployed and click **Next**.

    | Parameter | Value            | Description                          |
    | --------- | ---------------- | ------------------------------------ |
    | Namespace | `storageos`      | Namespace name for the deployment.   |
    | Name      | `ondat-operator` | Application name for the deployment. |

1. The next page will allow you to configure the Ondat Operator through Helm chart values. Under **Edit Options**, you are provided with 3 configurable sections called;

    * **Questions**
    * **Container Images**
    * **StorageOS Cluster**

1. Select the **StorageOS Cluster** section. This will show you a form with configurable parameters that have predefined values for an Ondat deployment. Below are following parameters that will need to be populated before beginning the installation;

    | Parameter                   | Value                 | Description                                                                                                                                                                                      |
    | --------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
    | Password                    | `$STORAGEOS_PASSWORD` | Password of the StorageOS administrator account. Must be at least 8 characters long, for example > `storageos`                                                                                   |
    | External `etcd` address(es) | `$ETCD_ENDPOINTS`     | List of `etcd` endpoints as comma-separated values. Prefer multiple direct endpoints over a single load-balanced endpoint, for example > `203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379` |

    > 💡 **Advanced Users** - For users who are looking to make further customisations to the Helm chart through additional configurable parameters or import your own `StorageOSCluster` custom resource manifest, review the Ondat Operator [README.md](https://github.com/ondat/charts/blob/main/charts/ondat-operator/README.md) document, [Cluster Operator Configuration](/docs/reference/cluster-operator/configuration) and  [Cluster Operator Examples](/docs/reference/cluster-operator/examples) reference pages for more information.

1. Once the parameters have been successfully populated, select **Install** to deploy Ondat.

#### Step 4 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd  # only if the etcd cluster was deployed inside the RKE cluster.
    kubectl get storageclasses | grep "storageos"
    ```

## Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Community Edition tier supports up to 1TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
