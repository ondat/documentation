---
title: "DigitalOcean Kubernetes (DOKS)"
linkTitle: "DigitalOcean Kubernetes (DOKS)"
weight: 10
description: >
    Walkthrough guide to install Ondat onto a DigitialOcean Kubernetes Cluster
---

## Overview

This guide will demonstrate how to install Ondat onto a [DigitalOcean Managed Kubernetes (DOKS)](https://www.digitalocean.com/products/kubernetes) cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/) or [Helm Chart](https://helm.sh/docs/intro/install/)

## Prerequisites

### 1 - Cluster and Node Prerequisites

The minimum cluster requirements for a **non-production installation** of ondat are as follows:

* Linux with a 64-bit architecture
* 2 vCPU and 8GB of memory
* 3 worker nodes in the cluster and sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster
* Make sure your DOKS cluster version is greater than or equal to `v1.21.10` or `v1.22.7` as they will have the required kernel modules available for Ondat to run successfully.
* Ensure the following firewall ports are open: [Firewalls and VPS providers](https://docs.ondat.io/docs/prerequisites/firewalls/#firewalls-and-vps-providers)

For a comprehensive list of prerequisites and how to build a **production installation** of Ondat please refer to [Ondat Prerequisites](https://docs.ondat.io/docs/prerequisites/)

### 2 - Client Tools Prerequisites

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

You can use either the [kubectl-storageos CLI](/docs/reference/kubectl-plugin/) or [Helm 3 CLI](https://helm.sh/docs/intro/install/) to install Ondat onto your cluster.  The most common way is to use Helm due to its popularity in the Kubernetes community, but both are fully supported and described below

### Step 3a - Installing via Helm

The Ondat Portal UI will display the following cmd that can be used to install Ondat using Helm

![Helm Install](/images/docs/install/HelmInstall.png)

1. The first set of commands adds the Ondat Helm repository and ensures a updated local cache.

```bash
helm repo add ondat https://ondat.github.io/charts && \
helm repo update && \
```

2. The last command installs Ondat with a set of basic install parameters that are sufficient for a basic trial installation.

```bash
helm install ondat ondat/ondat \
  --namespace=storageos \
  --create-namespace \
  --set ondat-operator.cluster.portalManager.enabled=true \
  --set ondat-operator.cluster.portalManager.clientId=37540b25-285c-4326-b76c-742100723ac3 \
  --set ondat-operator.cluster.portalManager.secret=e946f84a-e6c0-4afd-9087-f9cdd6906aa5 \
  --set ondat-operator.cluster.portalManager.apiUrl=https://portal-setup-7dy4neexbq-ew.a.run.app \
  --set ondat-operator.cluster.portalManager.tenantId=16e51eb9-37cf-4103-9a31-9e2cdaeec373 \
  --set etcd-cluster-operator.cluster.replicas=3 \
  --set etcd-cluster-operator.cluster.storage=6Gi \
  --set etcd-cluster-operator.cluster.resources.requests.cpu=100m \
  --set etcd-cluster-operator.cluster.resources.requests.memory=300Mi
```

3. The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 3b - Installing via `kubectl-storageosa plugin

The Ondat Portal UI will display the following cmd that can be used to install Ondat using the `kubectl-storageos` plugin:

![kubectl-storageos Install](/images/docs/install/PluginInstall.png)

This command uses the `kubectl-storageos` plugin command with a set of basic install parameters that are sufficient for a basic trial instalation. The installation process may take a few minutes.

```bash
kubectl storageos install \
  --include-etcd=true \
  --enable-portal-manager=true \
  --portal-client-id=37540b25-285c-4326-b76c-742100723ac3 \
  --portal-secret=e946f84a-e6c0-4afd-9087-f9cdd6906aa5 \
  --portal-api-url=https://portal-setup-7dy4neexbq-ew.a.run.app \
  --portal-tenant-id=16e51eb9-37cf-4103-9a31-9e2cdaeec373 \
  --etcd-cpu-limit=100m \
  --etcd-memory-limit=300Mi \
  --etcd-replicas=3
```

### Step 4 - Verifying Ondat Installation

Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status).

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
