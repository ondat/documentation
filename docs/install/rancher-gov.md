---
title: "Rancher Kubernetes Engine 2 (RKE2)"
linkTitle: "Rancher Kubernetes Engine 2 (RKE2)"
weight: 1
--- 

## Overview

This guide will demonstrate how to install Ondat onto a [Rancher Kubernetes Engine 2 (RKE2)](https://docs.rke2.io/), also known as RKE Government, cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/).

## Prerequisites

> ⚠️ Make sure you have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

> ⚠️ Make sure the following CLI utilities are installed on your local machine and are available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [kubectl-storageos](/docs/reference/kubectl-plugin/)

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing.

> ⚠️ Make sure you have a running RKE2 cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ Make sure your RKE2 cluster uses a Linux distribution that is officially supported by RKE2 as your node operating system and has the required LinuxIO related kernel modules are available for Ondat to run successfully. A strong recommendation would be to review [RKE2 Operating System Requirements](https://docs.rke2.io/install/requirements/#operating-systems) documentation to ensure that you are using a supported Linux distribution.

## Procedure

### Step 1 - Install Local Path Provisioner

1. By default, a newly provisioned RKE2 cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to provide local storage for Ondat's embedded `etcd` cluster operator deployment.

```bash
kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
```

2. Define and export the `ETCD_STORAGECLASS` environment variable so that value is `local-path`, which is the default StorageClass name for the Local Path Provisioner.

```bash
export ETCD_STORAGECLASS="local-path"
```

3. Verify that the Local Path Provisioner was successfully deployed and ensure that the deployment is in a  `RUNNING`  status, run the following  `kubectl`  commands.

```bash
kubectl get pod --namespace=local-path-storage
kubectl get storageclass
```

> ⚠️ The `local-path` StorageClass is only recommended for **non production** clusters as this stores all the data of the `etcd` peers locally, which makes it susceptible to state being lost on node failures.

### Step 2 - Conducting Preflight Checks

* Run the following command to conduct preflight checks against the RKE2 cluster to validate that Ondat prerequisites have been met before attempting an installation.

```bash
kubectl storageos preflight
```

### Step 3 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance.

```bash
export STORAGEOS_USERNAME="storageos"
export STORAGEOS_PASSWORD="storageos"
```

2. Run the following  `kubectl-storageos` plugin command to install Ondat.

```bash
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --etcd-storage-class="$ETCD_STORAGECLASS" \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

* The installation process may take a few minutes.

### Step 4 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
kubectl get all --namespace=storageos
kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

### Step 5 - Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
