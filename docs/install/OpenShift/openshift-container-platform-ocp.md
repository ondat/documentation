---
title: "OpenShift Container Platform (OCP)"
linkTitle: "OpenShift Container Platform (OCP)"
weight: 1
description: >
    Walkthrough guide to install Ondat onto an OpenShift Cluster.
---

## Overview

This guide will demonstrate how to install Ondat onto a [OpenShift Container Platform (OCP)](https://www.redhat.com/en/technologies/cloud-computing/openshift/container-platform) cluster using either the [Helm Chart](https://helm.sh/docs/intro/install/) or [Ondat `kubectl` / `oc` plugin](/docs/reference/kubectl-plugin/).

## Prerequisites

### 1 - Cluster & Node Prerequisites

The minimum cluster requirements for a **non-production installation** of ondat are as follows:

- Linux with a 64-bit architecture.
- 2 vCPU and 4GB of RAM per node.
- 3 worker nodes in the cluster and sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.
- Make sure the OS on your nodes are compatible with Ondat. See the [Ondat Prerequisites](https://docs.ondat.io/docs/prerequisites/)  for all supported linux distributions.
- Depending on how you have deployed OpenShift, be it either in a public or private cloud - ensure that you have persistent storage available to provide local storage for Ondat's embedded `etcd` cluster component that is used to manage the Ondat's configuration and volume state.

For a comprehensive list of prerequisites and how to build a **production installation** of Ondat please refer to [Ondat Prerequisites](https://docs.ondat.io/docs/prerequisites/)

### 2 - Client Tools Prerequisites

The following CLI utilities are installed on your local machine and available in your `$PATH`:

- [oc](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html)

Ondat can be installed either via Helm Chart or using our command-line tool.  Depending on which installation method you choose you will require either:

- [Ondat oc-storageos CLI](/docs/reference/kubectl-plugin/)
- [Helm 3 CLI](https://helm.sh/docs/intro/install/)

## Installation of Ondat

### Step 1 - Adding a Cluster

The Ondat Portal is how you can license and get the commands for installing Ondat.

- Either login or create an account on the [Ondat Portal](https://portal.ondat.io/).
- Choose the 'Install Ondat on your cluster' or 'Add cluster' options in the UI.
- Add a Name for your cluster and where it is going to be located. This will allow you to view the same prerequisites listed above.

### Step 2 - Choosing the Installation Method

You can use either the [oc-storageos CLI](/docs/reference/kubectl-plugin/) or [Helm 3 CLI](https://helm.sh/docs/intro/install/) to install Ondat onto your cluster.  The most common way is to use Helm due to its popularity in the Kubernetes community, but both are fully supported and described below.

### Step 3a - Installing via Helm

The Ondat Portal UI will display the following cmd that can be used to install Ondat using Helm. The command created will be unique for you and the screenshot below is just for reference.

![OpenShift Ondat Helm Installation](/images/docs/install/ocp-helm-install-portal.png)

The first two lines of the command adds the Ondat Helm repository and ensures a updated local cache.  The remaining command installs Ondat via Helm with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 3b - Installing via kubectl-storageos plugin

The Ondat Portal UI will display the following cmd that can be used to install Ondat using the `oc-storageos` plugin.  The command created will be unique for you and the screenshot below is just for reference.

![OpenShift Ondat oc-storageos Installion](/images/docs/install/ocp-plugin-install-portal.png)

The command that is provided by the Portal is unique to you and uses the `kubectl-storageos` plugin command with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 4 - Verifying Ondat Installation

Run the following `oc` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
oc get all --namespace=storageos
oc get all --namespace=storageos-etcd
oc get storageclasses | grep "storageos"
```

Once all the components are up and running the output should look like this:

![OpenShift Ondat Install Success](/images/docs/install/ocp-ondat-deployment-portal-success.png)

### Step 5 - Applying a Licence to the Cluster

Newly installed Ondat clusters must be licensed within 24 hours. For details of our Community Edition and pricing see [here](https://www.ondat.io/pricing).

To licence your cluster with the community edition:

1. On the Clusters page select 'View Details'
1. Click on 'Change Licence'
1. In the following pop-up select the 'Community Licence' option then click 'Generate'

This process generates a licence and installs it for you. Now you are good to go!
