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

* Your EKS clusters use [Ubuntu for EKS](https://cloud-images.ubuntu.com/docs/aws/eks/) as the default node operating system with an optimised kernel. For kernel versions below `linux-aws-5.4.0-1066.69` or `linux-aws-5.13.0-1014.15`, the module `tcm_loop` is not included in the base kernel distribution. In that case, the package `linux-modules-extra-$(uname -r)` is additionally required on each of the nodes - this can be installed automatically by adding it to the node's user data as in the example below.

To find the latest Ubuntu for EKS AMI, search your region for the image:

```bash
export AWS_REGION="eu-west-2" # Insert your preferred region here
aws ec2 describe-images \
--filters "Name=owner-id,Values=099720109477" "Name=architecture,Values=x86_64" "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" \
--query 'Images[?contains(Name, `ubuntu-eks`)] | [?contains(Name, `testing`) == `false`] | [?contains(Name, `minimal`) == `false`] | [?contains(Name, `hvm-ssd`) == `true`] | sort_by(@, &CreationDate)| [-1].ImageId' \
--output text \
--region "$AWS_REGION"
```

In this example, we have used [eksctl](https://eksctl.io/introduction/) to create a cluster with 3 nodes of size `t3.large` running Ubuntu for EKS in the `eu-west-2` region. We have provided `100 GB` of disk space for each node. Note that by default, Ondat will store data locally in the node's file system under the path `/var/lib/storageos` on each node in [hyperconverged mode](/docs/concepts/nodes/#hyperconverged-mode). In a production infrastructure, we would create multiple Elastic Block Store (EBS) Volumes tweaked for performance or use ephemeral SSD storage and [mount our volumes under data device directories](/docs/concepts/volumes/) with some additions to user data. We would also implement some form of snapshots or backup of these underlying volumes to ensure continuity in a disaster scenario.

```yaml
# cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ondat-cluster
  region: eu-west-2

addons:
  - name: aws-ebs-csi-driver

iam:
  withOIDC: true

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
    iam:
      withAddonPolicies:
        ebs: true
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

```bash
eksctl create cluster --config-file=cluster.yaml
```

> ⚠️ With the above configuration, volumes will be deleted when the nodes they
> are attached to are terminated. Be sure to keep snapshots, for example by using
> [Data Lifecycle Manager](https://aws.amazon.com/blogs/storage/automating-amazon-ebs-snapshot-and-ami-management-using-amazon-dlm/)

## Procedure

First, provision your `kubeconfig` for `kubectl` and test that you can connect to Kubernetes:

```bash
aws eks update-kubeconfig --region "$AWS_REGION" --name ondat-cluster
kubectl get nodes
```

If you receive the message `No resources found` or see nodes marked as `NotReady`, wait for 2-3 minutes in order for your nodes to transition to `Ready` and check again to ensure they are running before proceeding through the next steps.

### Step 1 - Conducting Preflight Checks

Run the following command to conduct preflight checks against the EKS cluster to ensure that Ondat prerequisites are in place before continuing with installation.

```bash
kubectl storageos preflight
```

### Step 2 - Installing Ondat

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance. Set the `StorageClass` for etcd to use (this cannot be Ondat, as Ondat is dependent upon etcd). On AWS EKS, we suggest `gp3` for a good balance of performance and resilience or `io2` where top performance is essential.

The default `StorageClass` in EKS is `gp2` which is not recommended, instead we will create a `gp3` `StorageClass` and set it as default, at least until we install Ondat:

```bash
kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
allowVolumeExpansion: true
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
EOF
```

> 💡 This `StorageClass` requires the AWS EBS EKS addon we specified in the `eksctl` cluster configuration above

```bash
export STORAGEOS_USERNAME="storageos"
export STORAGEOS_PASSWORD="storageos"
export ETCD_STORAGECLASS="gp3"
```

2. Run the following  `kubectl-storageos` plugin command to install Ondat.

```bash
kubectl storageos install \
  --include-etcd \
  --etcd-tls-enabled \
  --etcd-storage-class "$ETCD_STORAGECLASS" \
  --admin-username="$STORAGEOS_USERNAME" \
  --admin-password="$STORAGEOS_PASSWORD"
```

The installation process may take a few minutes.

### Step 3 - Verifying Ondat Installation

Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

```bash
kubectl get all --namespace=storageos
kubectl get all --namespace=storageos-etcd
kubectl get storageclasses | grep "storageos"
```

### Step 4 - Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our personal licence is free, and supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
