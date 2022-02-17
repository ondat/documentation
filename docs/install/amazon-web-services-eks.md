---
title: "Amazon Web Services Elastic Kubernetes Service (AWS EKS)"
linkTitle: "Amazon Web Services Elastic Kubernetes Service (AWS EKS)"
---

## Overview

This guide will demonstrate how to install Ondat onto a [Elastic Kubernetes Service](https://aws.amazon.com/eks/) cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/).

## Prerequisites

* You have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

* The following CLI utilities are installed on your local machine and are available in your `$PATH`:
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [kubectl-storageos](/docs/reference/kubectl-plugin/)

* You have a running EKS cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

* Your EKS clusters use [Ubuntu for EKS](https://cloud-images.ubuntu.com/docs/aws/eks/) as the default node operating system with an optimised kernel. For the kernel module `tcm_loop`, the package `linux-modules-extra-$(uname -r)` is additionally required on each of the nodes - this can be installed automatically by adding it to the node's userdata as in the example below.

In this example, we have used [eksctl](https://eksctl.io/introduction/) to create a cluster with 3 nodes of size `t3.large` running Ubuntu for EKS in the `eu-west-2` region. We have provided `100 GB` of disk space for each node - note that by default, Ondat will store data locally in the node's filesystem under the path `/var/lib/storageos` on each node in [hyperconverged mode](/docs/concepts/nodes/#hyperconverged-mode) - in a production infrastructure, we would likely create multiple EBS Volumes tweaked for performance or use ephemeral SSD storage and [mount our volumes under data device directories](/docs/concepts/volumes/) with some additions to userdata. We would also implement some form of snapshots or backup of these underlying volumes to ensure continuity in a disaster scenario.

```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ondat-cluster
  region: eu-west-2

managedNodeGroups:
  - name: ondat-ng
    minSize: 3
    maxSize: 3
    instanceType: t3.large
    ami: ami-0cb2cb474d9e4e075
    labels: {ondat: node}
    volumeSize: 100
    volumeName: /dev/xvda
    volumeEncrypted: true
    disableIMDSv1: true
    overrideBootstrapCommand: |
      #!/bin/bash
      mkdir -p /var/lib/storageos
      echo "/dev/nvme1n1 /var/lib/storageos ext4 defaults,discard 0 1" >> /etc/fstab
      mkfs.ext4 /dev/nvme1n1
      mount /var/lib/storageos
      sudo apt-get update
      sudo apt-get install -y linux-modules-extra-$(uname -r)
      /etc/eks/bootstrap.sh ondat-cluster
```

> ⚠️ With the above configuration, volumes will be deleted when the nodes they
> are attached to are terminated. Be sure to keep snapshots, eg. via
> [Data Lifecycle Manager](https://aws.amazon.com/blogs/storage/automating-amazon-ebs-snapshot-and-ami-management-using-amazon-dlm/)

## Procedure

### Step 1 - Conducting Preflight Checks

Run the following command to conduct preflight checks against the EKS cluster to validate that Ondat prerequisites have been met before attempting an installation.

```bash
kubectl storageos preflight
```

### Step 2 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance.

```bash
export STORAGEOS_USERNAME="admin"
export STORAGEOS_PASSWORD="password"
```

2. Run the following  `kubectl-storageos` plugin command to install Ondat.

```bash
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

The installation process may take a few minutes.

### Step 3 - Verifying Ondat Installation

Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
kubectl get all \
   --namespace=storageos && kubectl \ 
get all \
  --namespace=storageos-etcd &&
kubectl get storageclasses | grep "storageos"
```

### Step 4 - Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
