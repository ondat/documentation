---
title: "Amazon Elastic Kubernetes Service (EKS)"
linkTitle: "Amazon Elastic Kubernetes Service (EKS)"
weight: 5
description: >
    Walkthrough guide to install Ondat onto an EKS Cluster
---

## Overview

This guide will demonstrate how to install Ondat onto a [Amazon EKS](https://aws.amazon.com/eks/) cluster using either the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/) or [Helm Chart](https://helm.sh/docs/intro/install/).

## Prerequisites

### 1 - Cluster and Node Prerequisites

The minimum cluster requirements for a **non-production installation** of Ondat are as follows:

* Linux with a 64-bit architecture.
* 2 vCPU and 4GB of RAM per node.
* 3 worker nodes in the cluster and sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.
* Make sure your EKS clusters use [Ubuntu for EKS](https://cloud-images.ubuntu.com/docs/aws/eks/) as the default node operating system with an optimised kernel.  This installation guide takes you through that process as it is not easily available in the AWS Console.
* For more information on the Linux distributions that are supported, and how to update Amazon Linux with the correct Kernal Modules, see [System Configuration](/docs/prerequisites/systemconfiguration/).

For a comprehensive list of prerequisites and how to build a **production installation** of Ondat please refer to [Ondat Prerequisites](https://docs.ondat.io/docs/prerequisites/)

### 2 - Client Tools Prerequisites

The following CLI utilities are installed on your local machine and available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [aws](https://aws.amazon.com/cli/)
* [eksctl](https://eksctl.io/), at least version `>=0.83.0`

Ondat can be installed either via Helm Chart or using our command-line tool.  Depending on which installation method you choose you will require either:

* [kubectl-storageos CLI](/docs/reference/kubectl-plugin/)
* [Helm 3 CLI](https://helm.sh/docs/intro/install/)

### 3 - Creating a cluster with the correct Linux distribution

In this example, we have used [eksctl](https://eksctl.io/introduction/) to create a cluster with 3 nodes of size `i3en.xlarge` running Ubuntu for EKS in the `eu-west-2` region. We have provided `20 GB` of disk space for each node. With a default installation Ondat will store data locally in the node's file system under the path `/var/lib/storageos` on each node in [hyperconverged mode](/docs/concepts/nodes/#hyperconverged-mode).  In a production infrastructure, we would create multiple Elastic Block Store (EBS) Volumes tweaked for performance or use ephemeral SSD storage and [mount our volumes under data device directories](/docs/concepts/volumes/) with some additions to user data. We would also implement some form of snapshots or backup of these underlying volumes to ensure continuity in a disaster scenario.

#### 3a - Creating the cluster.yaml file

Create the following `cluster.yaml` file that will be used to create your cluster. Make the following updates:

* The file to use the `region` and `availabilityZones` that you need
* The `<key-name>` field in the publicKeyName parameter - make sure you update this to match your ssh key name.

```yaml
# cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ondat-cluster
  region: eu-west-2
  version: "1.22"

addons:
  - name: aws-ebs-csi-driver

iam:
  withOIDC: true

managedNodeGroups:
  - name: ondat-ng-2a
    availabilityZones:
      - eu-west-2a
    minSize: 1
    maxSize: 3
    desiredCapacity: 1
    instanceType: i3en.xlarge
    amiFamily: Ubuntu2004
    ssh:
      allow: true
      publicKeyName: <key-name>
    labels: {ondat: node}
    volumeSize: 20
    volumeType: gp3
    volumeEncrypted: true
    disableIMDSv1: true
    iam:
      withAddonPolicies:
        ebs: true
    preBootstrapCommands:
      - mkdir -p /var/lib/storageos
      - echo "/dev/nvme1n1 /var/lib/storageos ext4 defaults,discard 0 1" >> /etc/fstab
      - mkfs.ext4 /dev/nvme1n1
      - mount /var/lib/storageos

  - name: ondat-ng-2b
    availabilityZones:
      - eu-west-2b
    minSize: 1
    maxSize: 3
    desiredCapacity: 1
    instanceType: i3en.xlarge
    amiFamily: Ubuntu2004
    ssh:
      allow: true
      publicKeyName: <key-name>
    labels: {ondat: node}
    volumeSize: 20
    volumeType: gp3
    volumeEncrypted: true
    disableIMDSv1: true
    iam:
      withAddonPolicies:
        ebs: true
    preBootstrapCommands:
      - mkdir -p /var/lib/storageos
      - echo "/dev/nvme1n1 /var/lib/storageos ext4 defaults,discard 0 1" >> /etc/fstab
      - mkfs.ext4 /dev/nvme1n1
      - mount /var/lib/storageos

  - name: ondat-ng-2c
    availabilityZones:
      - eu-west-2c
    minSize: 1
    maxSize: 3
    desiredCapacity: 1
    instanceType: i3en.xlarge
    amiFamily: Ubuntu2004
    ssh:
      allow: true
      publicKeyName: <key-name>
    labels: {ondat: node}
    volumeSize: 20
    volumeType: gp3
    volumeEncrypted: true
    disableIMDSv1: true
    iam:
      withAddonPolicies:
        ebs: true
    preBootstrapCommands:
      - mkdir -p /var/lib/storageos
      - echo "/dev/nvme1n1 /var/lib/storageos ext4 defaults,discard 0 1" >> /etc/fstab
      - mkfs.ext4 /dev/nvme1n1
      - mount /var/lib/storageos

```

#### 3b - Creating the cluster

Once you have created the yaml file above, run the following eksctl command to create your cluster.

```bash
eksctl create cluster --config-file=cluster.yaml
```

⚠️ With the above configuration, volumes will be deleted when the nodes they are attached to are terminated. Be sure to keep snapshots, for example by using [Data Lifecycle Manager](https://aws.amazon.com/blogs/storage/automating-amazon-ebs-snapshot-and-ami-management-using-amazon-dlm/).

### 4 - Connecting to your cluster

First, provision your `kubeconfig` for `kubectl` and test that you can connect to Kubernetes.  You will need to update the script with the region where your cluster is.

```bash
export AWS_REGION="eu-west-2" # Insert your preferred region here
aws eks update-kubeconfig --region AWS_REGION --name ondat-cluster
kubectl get nodes
```

If you receive the message `No resources found` or see nodes marked as `NotReady`, wait for 2-3 minutes in order for your nodes to transition to `Ready` and check again to ensure they are running before proceeding through the next steps.

### 5 - Creating a StorageClass for etcd to use

If you used the `eksctl` cluster configuration defined above, the gp3 storage class is already available so you can skip to the next step. Otherwise you can set up the EBS CSI Driver as follows:

> It is important to note that the Ondat etcd usage of disk depends on the size of the Kubernetes cluster. However, it is recommended that the disks have at least 800 IOPS at any point in time. The best cost-effective storage class that fulfils such requirements is gp3. If gp2 is used, it is paramount to use a volume bigger than 256Gi as it will have enough IOPS even when the burstable credits are exhausted.

To use a gp3 storage class in Kubernetes it is required to install the Amazon CSI Driver. Follow [this guide] (<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>) to install. Follow the steps below:

1. [Create IAM permissions](https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html)
1. Install the CSI driver
1. [Using EKS addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html)
1. [Using self-managed add on](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md) (AWS clusters, but not in EKS)
1. Install the `gp3` `StorageClass`:

  ```bash
  kubectl create -f - <<EOF
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: gp3
  allowVolumeExpansion: true
  provisioner: ebs.csi.aws.com
  volumeBindingMode: WaitForFirstConsumer
  parameters:
    type: gp3
  EOF
  ```

## Installation of Ondat

### Step 1 - Adding a Cluster

The Ondat Portal is how you can license and get the commands for installing Ondat:

* Either login or create an account on the [Ondat Portal](https://portal.ondat.io/)
* Choose the 'Install Ondat on your cluster' or 'Add cluster' options the UI
* Add a Name for your cluster and where it is going to be located

### Step 2 - Choosing the Installation Method

You can use either the [kubectl-storageos CLI](/docs/reference/kubectl-plugin/) or [Helm 3 CLI](https://helm.sh/docs/intro/install/) to install Ondat onto your cluster.  The most common way is to use Helm due to its popularity in the Kubernetes community, but both are fully supported and described below

### Step 3a - Installing via Helm

The Ondat Portal UI will display the following cmd that can be used to install Ondat using Helm. The command created will be unique for you and the screenshot below is just for reference.

![Helm Install](/images/docs/install/HelmInstall.png)

The first two lines of the command adds the Ondat Helm repository and ensures a updated local cache.  The remaining command installs Ondat via Helm with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

### Step 3b - Installing via kubectl-storageos plugin

The Ondat Portal UI will display the following cmd that can be used to install Ondat using the `kubectl-storageos` plugin.  The command created will be unique for you and the screenshot below is just for reference.

![kubectl-storageos Install](/images/docs/install/PluginInstall.png)

The command that is provided by the Portal is unique to you and uses the `kubectl-storageos` plugin command with a set of basic install parameters that are sufficient for a basic trial installation and to connect the Ondat installation with your portal account for licensing.  The installation process may take a few minutes. The end of this guide contains information on verifying the installation and licensing.

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

Newly installed Ondat clusters must be licensed within 24 hours. For details of our Community Edition and pricing see our [pricing page](https://www.ondat.io/pricing).

To licence your cluster with the community edition:

1. On the Clusters page select 'View Details'
1. Click on 'Change Licence'
1. In the following pop-up select the 'Community Licence' option then click 'Generate'

This process generates a licence and installs it for you. Now you are good to go!
