---
title: "Microsoft Azure Kubernetes Service (AKS)"
linkTitle: "Microsoft Azure Kubernetes Service (AKS)"
---

## Overview

This guide will walk through and demonstrate how to install Ondat onto a [Microsoft Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-gb/services/kubernetes-service/) cluster using the [Ondat kubectl plugin](https://docs.ondat.io/docs/reference/kubectl-plugin/).

## Prerequisites

Ensure that you have reviewed and met the following prerequisites below before installing Ondat. 
> ⚠️ Ensure that you have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](https://docs.ondat.io/docs/prerequisites/) page for more information.

> ⚠️ Ensure that the following CLI utilities are installed on your local machine and are available in your `$PATH`;
>- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) 
>- [kubectl-storageos](https://docs.ondat.io/docs/reference/kubectl-plugin/) 

> ⚠️ This installation guide assumes that the end user already has a running AKS cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ AKS clusters use [Ubuntu](https://ubuntu.com/) as the default node operating system with an optimised kernel. Any Ubuntu based node operating system with a kernel version greater than `4.15.0-1029-azure` is compatible with Ondat.

## Procedure

### Step 1 - Conduct Preflight Checks First

- Run the following command to conduct preflight checks against the AKS cluster to validate that Ondat prerequisites have been met before attempting an installation.

```bash
kubectl storageos preflight
```

- If the preflight checks have been successfully passed, proceed to the next step.

### Step 2 - Install Ondat

- Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables first that will be used to manage your Ondat instance.

```bash
export STORAGEOS_USERNAME="admin"
export STORAGEOS_PASSWORD="password"
``` 

- Once set, run the following  `kubectl-storageos` plugin command to install Ondat.

```bash
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

- Wait for a couple of minutes for the installation process to complete successfully before moving onto the next step.

### Step 3 - Verify Ondat Installation

- To verify that Ondat was successfully deployed, and the core components are all in a `RUNNING` status, run the following `kubectl` commands to inspect Ondat's resources.

```bash
kubectl get all --namespace=storageos && kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

### Step 4 - Apply A Licence To The Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

- To obtain a licence, follow the instructions on our [licensing operations](https://docs.ondat.io/docs//operations/licensing) page.