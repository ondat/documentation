---
title: "OpenShift via OperatorHub"
linkTitle: "OpenShift via OperatorHub"
weight: 5
description: >
     Walkthrough guide to install Ondat onto an OpenShift Cluster via OperatorHub
---

## Overview

This guide will demonstrate how to install Ondat onto an [Openshift](/docs/platforms/openshift) cluster using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/).

## Prerequisites

> ⚠️ Make sure the
> [prerequisites for Ondat](/docs/prerequisites/) are
> satisfied before proceeding. Including the deployment of an etcd cluster and
> configuration of CRI-O PID limits.

> ⚠️ If you have installed OpenShift in AWS ensure that the requisite ports are
> opened for the worker nodes' security group.

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing. You can request a licence via the [Ondat SaaS Platform](https://portal.ondat.io/).

> 💡 For OpenShift upgrades, refer to the
> [OpenShift platform page](/docs/platforms/openshift#openshift-upgrades).

Ondat v2 supports OpenShift v4. For more information, see the [OpenShift platform](/docs/platforms/openshift) page.

## installation of Ondat via OperatorHub

#### Step 1: Operatorhub

1. Select the `OperatorHub` from the Catalog sub menu and search for StorageOS

   > 💡 Choose between using the RedHat Marketplace or the Community Operators
   > installation.

2. Select StorageOS and click __Install__.

3. Select the relevant install options.

    > Make sure the `Approval Strategy` is set to __Manual__. This option makes sure that the StorageOS
    > Operator doesn't upgrade versions without explicit approval.

4. Start the approval procedure by clicking on the operator name.

5. On __Subscription Details__, click the approval link.

6. On __Review Manual Install__ panel in the __Components__ tab, click __Approve__ to confirm the installation.

The Ondat Cluster Operator is installed along the required CRDs.

#### Step 2: Authentication

1. Create a Secret in the `openshift-operators` project and select the YAML option to create a secret containing the `username` and an
   `password` key. The username and password defined in the secret will be
   used to authenticate when using the Ondat CLI and GUI. Take note of
   which project you created the secret in.

    Input the secret as YAML for simplicity.

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: storageos-api
      namespace: openshift-operators
    type: "kubernetes.io/storageos"
    data:
      # echo -n '<secret>' | base64
      username: c3RvcmFnZW9z
      password: c3RvcmFnZW9z
    ```

2. Go to the __Operators__->__Installed Operators__ and verify that the StorageOS Cluster Operator is installed.

3. Go to the __StorageOS Cluster__ section.

4. Click __Create StorageOSCluster__.

    > 💡 An Ondat Cluster is defined using a Custom Resource Definition

5. Create the Custom Resource

   The StorageOS cluster resource describes the Ondat cluster that will be
   created. Parameters such as the `secretRefName`, the `secretRefNamespace` and
   the `kvBackend.address` are mandatory.

   > 💡 Additional `spec` parameters are available on the [Cluster Operator configuration](/docs/reference/cluster-operator/configuration) page.

   ```bash
   apiVersion: "storageos.com/v1"
   kind: StorageOSCluster
   metadata:
     name: storageos
     namespace: openshift-operators
   spec:
     # Ondat Pods are in kube-system by default
     secretRefName: "storageos-api" # Reference the Secret created in the previous step
     secretRefNamespace: "openshift-operators"  # Namespace of the Secret created in the previous step
     k8sDistro: "openshift"
     kvBackend:
       address: 'storageos-etcd-client.etcd:2379' # Example address, change for your etcd endpoint
     # address: '10.42.15.23:2379,10.42.12.22:2379,10.42.13.16:2379' # You can set ETCD server ips
     resources:
       requests:
         memory: "512Mi"
         cpu: 1
     # nodeSelectorTerms:
     #   - matchExpressions:
     #     - key: "node-role.kubernetes.io/worker" # Compute node label will vary according to your installation
     #       operator: In
     #       values:
     #       - "true"
   ```

6. Verify that the StorageOS Cluster resource status is __Running__.

    > It can take up to a minute to report the Ondat Pods ready.

7. Check the StorageOS Pods in the `kube-system` project

    > A Status of 3/3 in the __Ready__ column for the Daemonset Pods indicates that Ondat is
    > bootstrapped successfully.

## License cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Community Edition tier supports up to 1TiB of provisioned storage.

To obtain a license, follow the instructions on our [licensing operations](/docs/operations/licensing) page.

## First Ondat volume

If this is your first installation you may wish to follow the [Ondat volume guide](/docs/operations/firstpvc) for an example of how
to mount an Ondat volume in a Pod.
