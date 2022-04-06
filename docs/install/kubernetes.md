---
title: "Kubernetes"
linkTitle: "Kubernetes"
weight: 1
---
## Overview

This guide will demonstrate how to install Ondat onto a [Kubernetes](https://kubernetes.io/docs/setup/) cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/). Ondat requires an `etcd` cluster to successfully run, which can be deployed through two different methods listed below;
  
  1. **Embedded `etcd` Deployment** - deploy an `etcd` cluster operator into your Kubernetes cluster, recommended for **non production** environments.
  1. **External `etcd` Deployment** - deploy an `etcd` cluster in dedicated virtual machines, recommended for **productdion** environments.

> 💡 For users who are looking to deploy Ondat onto a managed/specific Kubernetes distribution such AKS, EKS, GKE, RKE or DOKS, a recommendation would be to review the [Install](https://docs.ondat.io/docs/install/) section and choose the appropriate installation guide for your Kubernetes distribution.

## Prerequisites

> ⚠️ Make sure you have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

> ⚠️ Make sure the following CLI utilities are installed on your local machine and are available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [kubectl-storageos](/docs/reference/kubectl-plugin/)

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing.

> ⚠️ Make sure you have a running Kubernetes cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ Make sure your Kubernetes cluster uses a Linux distribution that is officially supported by Ondat as your node operating system and has the required LinuxIO related kernel modules are available for Ondat to run successfully.

## Procedure

### Option A - Using An Embedded `etcd` Deployment

#### Step 1 - Install Local Path Provisioner

1. By default, a newly provisioned Kubernetes cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to provide local storage for Ondat's embedded `etcd` cluster operator deployment.

    ```bash
    kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
    ```

1. Define and export the `ETCD_STORAGECLASS` environment variable so that value is `local-path`, which is the default StorageClass name for the Local Path Provisioner.

    ```bash
    export ETCD_STORAGECLASS="local-path"
    ```

1. Verify that the Local Path Provisioner was successfully deployed and ensure that that the deployment is in a  `RUNNING`  status, run the following  `kubectl`  commands.

    ```bash
    kubectl get pod --namespace=local-path-storage
    kubectl get storageclass
    ```

> ⚠️ The `local-path` StorageClass is only recommended for **non production** clusters as this stores all the data of the `etcd` peers locally which makes it susceptible to state being lost on node failures.

#### Step 2 - Conducting Preflight Checks

* Run the following command to conduct preflight checks against the Kubernetes cluster to validate that Ondat prerequisites have been met before attempting an installation.

    ```bash
    kubectl storageos preflight
    ```

#### Step 3 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance.

    ```bash
    export STORAGEOS_USERNAME="storageos"
    export STORAGEOS_PASSWORD="storageos"
    ```

1. Run the following  `kubectl-storageos` plugin command to install Ondat.

    ```bash
    kubectl storageos install \
      --include-etcd \
      --etcd-tls-enabled \
      --etcd-storage-class="$ETCD_STORAGECLASS" \
      --admin-username="$STORAGEOS_USERNAME" \
      --admin-password="$STORAGEOS_PASSWORD"
    ```

* The installation process may take a few minutes.

#### Step 4 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd
    kubectl get storageclasses | grep "storageos"
    ```

### Option A - Using An External `etcd` Deployment

#### Step 1 - Setup An `etcd` Cluster

* Ensure that you have an `etcd` cluster deployed first before installing Ondat. For instructions on how to set up an external `etcd` cluster, review the [`etcd` documentation](https://docs.ondat.io/docs/prerequisites/etcd/#production---etcd-on-external-virtual-machines) page.
* Once you have an `etcd` cluster up and running, ensure that you note down the list of `etcd` endpoints as comma-separated values that will be used when configuring Ondat in **Step 3**.
  * For example, `203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379`

#### Step 2 - Conducting Preflight Checks

* Run the following command to conduct preflight checks against the Kubernetes cluster to validate that Ondat prerequisites have been met before attempting an installation.

    ```bash
    kubectl storageos preflight
    ```

#### Step 3 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance. In addition, define and export a `ETCD_ENDPOINTS` environment variable, where the value will be a list of `etcd` endpoints as comma-separated values noted down earlier in **Step 2**.

    ```bash
    export STORAGEOS_USERNAME="storageos"
    export STORAGEOS_PASSWORD="storageos"
    export ETCD_ENDPOINTS="203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379"
    ```

1. Run the following  `kubectl-storageos` plugin command to install Ondat.

    ```bash
    kubectl storageos install \
      --etcd-endpoints="$ETCD_ENDPOINTS" \
      --admin-username="$STORAGEOS_USERNAME" \
      --admin-password="$STORAGEOS_PASSWORD"
    ```

* The installation process may take a few minutes.

#### Step 4 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get storageclasses | grep "storageos"
    ```

### Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
