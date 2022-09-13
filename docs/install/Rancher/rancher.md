---
title: "Rancher Kubernetes Engine (RKE)"
linkTitle: "Rancher Kubernetes Engine (RKE)"
weight: 10
description: >
    Walkthrough guide to install Ondat onto a Rancher Cluster
---

## Overview

This guide will demonstrate how to install Ondat onto a [Rancher Kubernetes Engine (RKE)](https://rancher.com/products/rke) cluster using either the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/) or [Helm Chart](https://helm.sh/docs/intro/install/)

## Prerequisites

### 1 - Cluster and Node Prerequisites

The minimum requirements for the nodes are as follows:

* Linux with a 64-bit architecture
* 2 vCPU and 4GB of RAM per node.
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

## Installation of Ondat

### Step 1 - Adding a Cluster

The Ondat Portal is how you can license and get the commands for installing Ondat

* Either login or create an account on the [Ondat Portal](https://portal.ondat.io/)
* Choose the 'Install Ondat on your cluster' or 'Add cluster' options in the UI
* Add a Name for your cluster and where it is going to be located.  This will allow you to view the same prerequisites as are listed above

### Step 2 - Choosing the Installation Method

You can use either the [kubectl-storageos CLI](/docs/reference/kubectl-plugin/) or [Helm 3 CLI](https://helm.sh/docs/intro/install/) to install Ondat onto your cluster.  The most common way is to use Helm due to its popularity in the Kubernetes community, but both are fully supported and described below.

### Step 3a - Installing via Helm

The Ondat Portal UI will display the following cmd that can be used to install Ondat using Helm. The command created will be unique for you and the screenshot below is just for reference.

![Helm Install](/images/docs/install/HelmInstall.png)

The first two lines of the command adds the Ondat Helm repository and ensures a updated local cache.  The remaining command installs Ondat via Helm with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 3b - Installing via kubectl-storageos plugin

The Ondat Portal UI will display the following cmd that can be used to install Ondat using the `kubectl-storageos` plugin.  The command created will be unique for you and the screenshot below is just for reference.

![kubectl-storageos Install](/images/docs/install/PluginInstall.png)

The command that is provided by the Portal is unique to you and uses the `kubectl-storageos` plugin command with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 4 - Verifying Ondat Installation

Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
kubectl get all --namespace=storageos
kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

Once all the components are up and running the output should look like this:

![Install Success](/images/docs/install/InstallSuccess.png)

### Step 5 - Applying a Licence to the Cluster

Newly installed Ondat clusters must be licensed within 24 hours. For details of our Community Edition and pricing see [here](https://www.ondat.io/pricing).

To licence your cluster with the community edition:

1. On the Clusters page select 'View Details'
1. Click on 'Change Licence'
1. In the following pop-up select the 'Community Licence' option then click 'Generate'

This process generates a licence and installs it for you. Now you are good to go!
