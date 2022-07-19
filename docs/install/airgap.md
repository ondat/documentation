---
title: "Air-Gapped Install"
linkTitle: "Air-Gapped Install"
weight: 90
---

## Overview

This guide will demonstrate how to install Ondat onto clusters that don't have direct access to the internet - i.e., [air-gapped](https://en.wikipedia.org/wiki/Air_gap_%28networking%29) environments. Air-gapped environments require cluster administrators to explicitly ensure that Ondat components are locally available before the installation.

> 💡 This guide is recommended for **advanced users** who have experience and permissions to be able to manage air-gapped deployments in their environment. The full procedure for this deployment method is estimated to take ~60 minutes to complete.

Below is a quick summary of the procedure that will be covered in this guide:

1. Install the Ondat kubectl plugin.
1. Generate the Ondat deployment manifests for your use case.
1. Push Ondat container images to your private registry.
1. Modify the Ondat deployment manifests.
1. Install Ondat onto your air-gapped cluster.

## Prerequisites

> ⚠️ Make sure you have met the minimum resource requirements for Ondat so your set up would be successful. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

> ⚠️ Make sure the following CLI utility is installed on your local machine and is available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing. You can request a licence via the [Ondat SaaS Platform](https://portal.ondat.io/).

> ⚠️ Make sure you have a running Kubernetes cluster with a minimum of 5 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ Make sure your Kubernetes cluster uses a Linux distribution that is officially supported by Ondat as your node operating system.

> ⚠️ Make sure that the node operating system have the required LinuxIO related kernel modules are available for Ondat to run successfully.

## Procedure

### Step 1 - Install Ondat Kubectl Plugin

* Ensure that the Ondat kubectl plugin is installed on your local machine and is available in your `$PATH`:
  * [kubectl-storageos](/docs/reference/kubectl-plugin/)

### Step 2 - Conducting Preflight Checks

* Run the following command to conduct preflight checks against the Kubernetes cluster to validate that Ondat prerequisites have been met before attempting an installation.

    ```bash
    kubectl storageos preflight
    ```

### Step 3 - Generate Ondat Deployment Manifests

#### Option A - Using An Embedded `etcd` Deployment

##### Install Local Path Provisioner

1. By default, a newly provisioned Kubernetes cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to provide local storage for Ondat's embedded `etcd` cluster operator deployment.
    > 💡 Different Kubernetes distributions may include a CSI driver as part of the deployment. Cluster administrators can leverage the CSI driver provided by their distribution if they don’t want to use a Local Path Provisioner. If so, ensure that the  `ETCD_STORAGECLASS`  environment variable points to the correct value for your Kubernetes distribution’s default StorageClass name.

    ```bash
    # Download the Local Path Provisioner.
    wget https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml
    
    # Get the list of images and push them to your private registry.
    grep "image:" local-path-storage.yaml

    # Modify the manifest and add the private registry URL to pull the images.
    vi local-path-storage.yaml

    # Deploy the Local Path Provisioner.
    kubectl apply --filename=local-path-storage.yaml
    ```

1. Define and export the `ETCD_STORAGECLASS` environment variable so that value is `local-path`, which is the default StorageClass name for the Local Path Provisioner.

    ```bash
    export ETCD_STORAGECLASS="local-path"
    ```

1. Verify that the Local Path Provisioner was successfully deployed and ensure that the deployment is in a  `RUNNING`  status, run the following  `kubectl`  commands.

    ```bash
    kubectl get pod --namespace=local-path-storage
    kubectl get storageclass
    ```

> ⚠️ The `local-path` StorageClass is only recommended for **non-production** clusters, as this stores all the data of the `etcd` peers locally, which makes it susceptible to its state being lost on node failures.

##### Generate Manifests

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance. In addition, define and export a `KUBERNETES_VERSION` environment variable, where the value will be the exact version of your Kubernetes cluster where Ondat is going to be deployed - for example, `v1.23.5`.

    ```bash
    export STORAGEOS_USERNAME="storageos"
    export STORAGEOS_PASSWORD="storageos"
    export KUBERNETES_VERSION="v1.23.5"
    ```

1. Run the following  `kubectl-storageos` plugin command with the `--dry-run` flag to generate the Ondat deployment Kubernetes manifests in a directory, called `storageos-dry-run`.

    ```bash
    kubectl storageos install \
      --dry-run \
      --include-etcd \
      --etcd-tls-enabled \
      --etcd-storage-class="$ETCD_STORAGECLASS" \
      --k8s-version="$KUBERNETES_VERSION" \
      --admin-username="$STORAGEOS_USERNAME" \
      --admin-password="$STORAGEOS_PASSWORD"
    ```

1. To review the list of manifests generated in the newly created `storageos-dry-run` directory, run the following commands.

    ```bash
    cd storageos-dry-run/
    ls
    ```

#### Option B - Using An External `etcd` Deployment

##### Setup An  `etcd`  Cluster

* Ensure that you have an  `etcd`  cluster deployed first before installing Ondat. For instructions on how to set up an external  `etcd`  cluster, review the  [`etcd`  documentation](/docs/prerequisites/etcd/#production---etcd-on-external-virtual-machines)  page.
* Once you have an  `etcd`  cluster up and running, ensure that you note down the list of  `etcd`  endpoints as comma-separated values that will be used when configuring Ondat.
  * For example,  `203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379`

##### Generate Manifests

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance. In addition, define and export a `KUBERNETES_VERSION` environment variable, where the value will be the exact version of your Kubernetes cluster where Ondat is going to be deployed - for example, `v1.23.5`. Lastly, define and export a `ETCD_ENDPOINTS` environment variable, where the value will be a list of `etcd` endpoints as comma-separated values.

    ```bash
    export STORAGEOS_USERNAME="storageos"
    export STORAGEOS_PASSWORD="storageos"
    export KUBERNETES_VERSION="v1.23.5"
    export ETCD_ENDPOINTS="203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379"
    ```

1. Run the following  `kubectl-storageos` plugin command with the `--dry-run` flag to generate the Ondat deployment Kubernetes manifests in a directory, called `storageos-dry-run`.

    ```bash
    kubectl storageos install \
      --dry-run \
      --skip-etcd-endpoints-validation \
      --etcd-endpoints="$ETCD_ENDPOINTS" \
      --k8s-version="$KUBERNETES_VERSION" \
      --admin-username="$STORAGEOS_USERNAME" \
      --admin-password="$STORAGEOS_PASSWORD"
    ```

1. To review the list of manifests generated in the newly created `storageos-dry-run` directory, run the following commands.

    ```bash
    cd storageos-dry-run/
    ls
    ```

### Step 4 - Push Ondat Images To Private Registry

 1. Get the list of all the container images required for Ondat to be deployed successfully and push them to your private registry which will be accessible through your air-gapped environment.

    ```bash
    grep --extended-regexp "RELATED|image:" *.yaml
    ```

 2. You will also need to pull the kubernetes scheduler image for your release and push that to your private registry.

    ```bash
    export KUBERNETES_VERSION="v1.23.5"
    docker pull k8s.gcr.io/kube-scheduler:${KUBERNETES_VERSION}
    ```

### Step 5 - Modify Deployment Manifests

 1. **`etcd-operator`** - Modify the `2-etcd-operator.yaml` manifest and apply the following changes.
     1. Locate the `storageos-etcd-controller-manager`  `Deployment` YAML, navigate to `manager` container and locate the `args` section.
     1. In this section, add a flag called `--etcd-repository=` where the value will be your `$PRIVATE_REGISTRY_URL/quay.io/coreos/etcd`. For example;

        ```yaml
        # Before modification.
            spec:
              containers:
              - args:
                - --enable-leader-election
                - --proxy-url=storageos-proxy.storageos-etcd.svc
        ```

        ```yaml
        # After modification.
            spec:
              containers:
              - args:
                - --enable-leader-election
                - --proxy-url=storageos-proxy.storageos-etcd.svc
                - --etcd-repository=$PRIVATE_REGISTRY_URL/quay.io/coreos/etcd  
        ```

 1. **`etcd-cluster`** - Modify the `3-etcd-cluster.yaml` manifest and apply the following changes.
    1. Locate the `storageos-etcd`  `CustomResource` YAML, navigate to the `storage` section and set the `storage` size value from `1Gi` to `256Gi`. For example;

        ```yaml
        # Before modification.
          storage:
            volumeClaimTemplate:
              resources:
                requests:
                  storage: 1Gi
        ```

        ```yaml
        # After modification.
          storage:
            volumeClaimTemplate:
              resources:
                requests:
                  storage: 256Gi
        ```

 1. **`storageos-operator`** - Modify the `0-storageos-operator.yaml` manifest and apply the following changes.
    1. Locate the `storageos-operator` `Deployment` YAML, navigate to the `manager` and `kube-rbac-proxy` containers.  Proceed to change the existing image registry URLs to point to your private registry URLs where the Ondat images reside. For example;

         ```yaml
          # Before modification.
                 name: manager
                 image: storageos/operator:v2.7.0

                 name: kube-rbac-proxy
                 image: quay.io/brancz/kube-rbac-proxy:v0.10.0
         ```

         ```yaml
         # After modification.
                 name: manager
                 image: $PRIVATE_REGISTRY_URL/operator:v2.7.0

                 name: kube-rbac-proxy
                 image: $PRIVATE_REGISTRY_URL/brancz/kube-rbac-proxy:v0.10.0
         ```

    1. Locate the `storageos-related-images` `ConfigMap` YAML, navigate to the environment variables that are prefixed with `RELATED_IMAGE_`. Proceed to change the existing image registry URLs to point to your private registry URLs where the Ondat images reside. For example;

        ```yaml
        # Before modification.
        kind: ConfigMap
        data:
          RELATED_IMAGE_API_MANAGER: storageos/api-manager:v1.2.9
          RELATED_IMAGE_CSIV1_EXTERNAL_ATTACHER_V3: quay.io/k8scsi/csi-attacher:v3.1.0
          RELATED_IMAGE_CSIV1_EXTERNAL_PROVISIONER: storageos/csi-provisioner:v2.1.1-patched
          RELATED_IMAGE_CSIV1_EXTERNAL_RESIZER: quay.io/k8scsi/csi-resizer:v1.1.0
          RELATED_IMAGE_CSIV1_LIVENESS_PROBE: quay.io/k8scsi/livenessprobe:v2.2.0
          RELATED_IMAGE_CSIV1_NODE_DRIVER_REGISTRAR: quay.io/k8scsi/csi-node-driver-registrar:v2.1.0
          RELATED_IMAGE_NODE_MANAGER: storageos/node-manager:v0.0.6
          RELATED_IMAGE_PORTAL_MANAGER: storageos/portal-manager:v1.0.2
          RELATED_IMAGE_STORAGEOS_INIT: storageos/init:v2.1.2
          RELATED_IMAGE_STORAGEOS_NODE: storageos/node:v2.7.0
          RELATED_IMAGE_NODE_GUARD: storageos/node-guard:v0.0.4
        ```

        ```yaml
        # After modification.
        kind: ConfigMap
        data:
          RELATED_IMAGE_API_MANAGER: $PRIVATE_REGISTRY_URL/api-manager:v1.2.9
          RELATED_IMAGE_CSIV1_EXTERNAL_ATTACHER_V3: $PRIVATE_REGISTRY_URL/k8scsi/csi-attacher:v3.1.0
          RELATED_IMAGE_CSIV1_EXTERNAL_PROVISIONER: $PRIVATE_REGISTRY_URL/csi-provisioner:v2.1.1-patched
          RELATED_IMAGE_CSIV1_EXTERNAL_RESIZER: $PRIVATE_REGISTRY_URL/k8scsi/csi-resizer:v1.1.0
          RELATED_IMAGE_CSIV1_LIVENESS_PROBE: $PRIVATE_REGISTRY_URL/livenessprobe:v2.2.0
          RELATED_IMAGE_CSIV1_NODE_DRIVER_REGISTRAR: $PRIVATE_REGISTRY_URL/k8scsi/csi-node-driver-registrar:v2.1.0
          RELATED_IMAGE_NODE_MANAGER: $PRIVATE_REGISTRY_URL/node-manager:v0.0.6
          RELATED_IMAGE_PORTAL_MANAGER: $PRIVATE_REGISTRY_URL/portal-manager:v1.0.2
          RELATED_IMAGE_STORAGEOS_INIT: $PRIVATE_REGISTRY_URL/init:v2.1.2
          RELATED_IMAGE_STORAGEOS_NODE: $PRIVATE_REGISTRY_URL/node:v2.7.0
          RELATED_IMAGE_NODE_GUARD: $PRIVATE_REGISTRY_URL/node-guard:v0.0.4
        ```

 1. **`storageos-cluster`**

> 💡 **Optional** - For users who are looking to make further customisations to their `StorageOSCluster` custom resource in the `1-storageos-cluster.yaml` manifest, review the [Cluster Operator Configuration](https://docs.ondat.io/docs/reference/cluster-operator/configuration) and [Cluster Operator Examples](https://docs.ondat.io/docs/reference/cluster-operator/examples) reference pages for more information.

### Step 6 - Installing Ondat

* Run the following  `kubectl` command to install Ondat with the generated manifests in the `storageos-dry-run` directory.

    ```bash
    # Apply the Operators and CustomResourceDefinitions (CRDs) first.
    find . -name '*-operator.yaml' | xargs -I{} kubectl apply --filename {}
    
    # Apply the Custom Resources next.
    find . -name '*-cluster.yaml' | xargs -I{} kubectl apply --filename {}
    ```

* The installation process may take a few minutes.

### Step 7 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd # only if the etcd cluster was deployed inside the Kubernetes cluster.
    kubectl get storageclasses | grep "storageos"
    ```

### Step 8 - Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Community Edition tier supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
