---
title: "Declarative Install"
linkTitle: "Declarative Install"
weight: 90
--- 

## Overview

This guide will demonstrate how to install Ondat onto a Kubernetes cluster declaratively. Ondat can be installed declaratively onto a Kubernetes cluster through two different methods;

1. Using the [Ondat kubectl plugin](/docs/reference/kubectl-plugin/).
1. Using the [Ondat Operator Helm chart](https://github.com/ondat/charts/tree/main/charts/ondat-operator).

## Prerequisites

> ⚠️ Make sure you have met the minimum resource requirements for Ondat to successfully run. Review the main [Ondat prerequisites](/docs/prerequisites/) page for more information.

> ⚠️ Make sure the following CLI utility is installed on your local machine and is available in your `$PATH`:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

> ⚠️ Make sure to add an [Ondat licence](/docs/operations/licensing/) after installing.

> ⚠️ Make sure you have a running Kubernetes cluster with a minimum of 3 worker nodes and the sufficient [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) permissions to deploy and manage applications in the cluster.

> ⚠️ Make sure your Kubernetes cluster uses a Linux distribution that is officially supported by Ondat as your node operating system and has the required LinuxIO related kernel modules are available for Ondat to run successfully.

## Procedure

### Option A - Using Ondat Kubectl Plugin

#### Step 1 - Install Ondat Kubectl Plugin

* Ensure that the Ondat kubectl plugin is installed on your local machine and is available in your `$PATH`:
  * [kubectl-storageos](/docs/reference/kubectl-plugin/)

#### Step 2 - Install Local Path Provisioner

1. By default, a newly provisioned Kubernetes cluster does not have any CSI driver deployed. Run the following commands against the cluster to deploy a [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to provide local storage for Ondat's embedded `etcd` cluster operator deployment.

    > 💡 Different Kubernetes distributions may include a CSI driver as part of the deployment. Cluster administrators can leverage the CSI driver provided by their distribution if they don't want to use a Local Path Provisioner. If so, ensure that the `ETCD_STORAGECLASS` environment variable points to the correct value for your Kubernetes distribution's default StorageClass name.

    ```bash
    kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
    ```

1. Define and export the `ETCD_STORAGECLASS` environment variable so that value is `local-path`, which is the default StorageClass name for the Local Path Provisioner.

    ```bash
    export ETCD_STORAGECLASS="local-path"
    ```

1. To verify that the Local Path Provisioner was successfully deployed and ensure that the deployment is in a  `RUNNING`  status, run the following  `kubectl`  commands.

    ```bash
    kubectl get pod --namespace=local-path-storage
    kubectl get storageclass
    ```

> ⚠️ The `local-path` StorageClass is only recommended for **non production** clusters, as this stores all the data of the `etcd` peers locally, which makes it susceptible to state being lost on node failures.

#### Step 3 - Conducting Preflight Checks

* Run the following command to conduct preflight checks against the Kubernetes cluster to validate that Ondat prerequisites have been met before attempting an installation.

    ```bash
    kubectl storageos preflight
    ```

#### Step 4 - Generate Ondat YAML Kubernetes Manifests

1. Define and export the `STORAGEOS_USERNAME` and `STORAGEOS_PASSWORD` environment variables that will be used to manage your Ondat instance. In addition, define and export a `KUBERNETES_VERSION` environment variable, where the value will be the exact version of your Kubernetes cluster where Ondat is going to be deployed - for example, `v1.23.5`.

    ```bash
    export STORAGEOS_USERNAME="storageos"
    export STORAGEOS_PASSWORD="storageos"
    export KUBERNETES_VERSION="v1.23.5"
    ```

1. Run the following  `kubectl-storageos` plugin command with the `--dry-run` flag to generate the Ondat YAML Kubernetes manifests in a directory, called `storageos-dry-run`.

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

1. To review the list of manifests generated in the newly created `storageos-dry-run` directory run the following commands.

    ```bash
    cd storageos-dry-run/
    ls storageos-dry-run/
    ```

#### Step 4 - Installing Ondat

1. Run the following  `kubectl` command to install Ondat with the generated manifests in the `storageos-dry-run` directory. The manifests  can also be used in your [GitOps](https://www.weave.works/technologies/gitops/) workflow to deploy Ondat, enabling you to have a fully declarative approach towards managing your infrastructure deployments.
    > 💡 **Advanced Users** - For users who are looking to make further customisations to their `StorageOSCluster` custom resource manifest, review the [Cluster Operator Configuration](/docs/reference/cluster-operator/configuration) and  [Cluster Operator Examples](/docs/reference/cluster-operator/examples) reference pages for more information.

    ```bash
    # Apply the Operators and CustomResourceDefinitions (CRDs) first.
    find . -name '*-operator.yaml' | xargs -I{} kubectl apply --filename {}
    
    # Apply the Custom Resources next.
    find . -name '*-cluster.yaml' | xargs -I{} kubectl apply --filename {}
    ```

* The installation process may take a few minutes.

#### Step 5 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd
    kubectl get storageclasses | grep "storageos"
    ```

### Option B - Using Ondat's Operator Helm Chart

#### Step 1 - Install Helm

* Ensure that the [Helm 3](https://helm.sh/) CLI utility is installed on your local machine and is available in your `$PATH`:
  * [helm](https://helm.sh/docs/intro/install/)

#### Step 2 - Setup An `etcd` Cluster

* Ensure that you have an `etcd` cluster deployed first before installing Ondat through the Helm chart. There are two different methods listed below with instructions on how to deploy an `etcd` cluster;

    1. [Embedded Deployment](https://docs.ondat.io/docs/prerequisites/etcd/#testing---installing-etcd-into-your-kubernetes-cluster) - deploy an `etcd` cluster operator into your Kubernetes cluster, recommended for **non production** environments.
    1. [External Deployment](https://docs.ondat.io/docs/prerequisites/etcd/#production---etcd-on-external-virtual-machines) - deploy an `etcd` cluster in dedicated virtual machines, recommended for **production** environments.

* Once you have an `etcd` cluster up and running, ensure that you note down the list of `etcd` endpoints as comma-separated values that will be used when configuring Ondat in **Step 4**.
  * For example, `203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379`

#### Step 3 - Configure Ondat's Helm Chart Repository

1. Add the Ondat Helm chart repository, update the local Helm repository index using the following `helm repo` commands.

    ```bash
    helm repo add ondat https://ondat.github.io/charts
    helm repo update
    ```

1. Check to confirm that the Ondat Helm chart repository is available using the following `helm` commands.

    ```bash
    helm repo list
    helm search repo "ondat"
    ```

#### Step 4 - Customising & Installing Ondat's Operator Helm Chart

* There are two ways to conduct an installation with Helm, **declaratively** by creating a custom `values.yaml` (recommended method) or **interactively** by using the `--set` flags to overwrite specific values for the deployment.

> 💡 **Advanced Users** - For users who are looking to make further customisations to the Helm chart through additional configurable parameters or manually create your own `StorageOSCluster` custom resource manifest, review the Ondat Operator [README.md](https://github.com/ondat/charts/blob/main/charts/ondat-operator/README.md) document, [Cluster Operator Configuration](/docs/reference/cluster-operator/configuration) and  [Cluster Operator Examples](/docs/reference/cluster-operator/examples) reference pages for more information.

##### Declarative (Recommended)

1. Make a copy of the [`values.yaml`](https://github.com/ondat/charts/blob/main/charts/ondat-operator/values.yaml) configuration file, rename it to `custom-values.yaml`, then ensure that the following configurable parameters have been populated before beginning the installation.
    * [`cluster.admin.password`](https://github.com/ondat/charts/blob/main/charts/ondat-operator/values.yaml#L60-L62)

    ```yaml
        # Password to authenticate to the StorageOS API with. This must be at least
        # 8 characters long.
        password: # for example -> storageos
    ```

    * [`cluster.kvBackend.address`](https://github.com/ondat/charts/blob/main/charts/ondat-operator/values.yaml#L71-L72)

    ```yaml
        # Key-Value store backend.
        kvBackend:
          address: # for example -> 203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379
    ```

1. Once the parameters above have been defined, run the following  `helm install`  command to install Ondat using the Helm chart. Ensure that you use the `--values=` flag with your `custom-values.yaml` file.

    ```bash
    helm install ondat-operator ondat/ondat-operator \
      --namespace=storageos \
      --create-namespace \
      --values=custom-values.yaml
    ```

* The installation process may take a few minutes.

##### Interactive

1. Define and export the `STORAGEOS_PASSWORD` environment variable that will be used to manage your Ondat instance. In addition, define and export a `ETCD_ENDPOINTS` environment variable, where the value will be a list of `etcd` endpoints as comma-separated values noted down earlier in **Step 2**.

    ```bash
    export STORAGEOS_PASSWORD="storageos"
    export ETCD_ENDPOINTS="203.0.113.10:2379,203.0.113.11:2379,203.0.113.12:2379"
    ```

1. Run the following  `helm install`  command to install Ondat using the Helm chart.

    ```bash
    helm install ondat-operator ondat/ondat-operator \
      --namespace=storageos \
      --create-namespace \
      --set cluster.admin.password="$STORAGEOS_PASSWORD" \
      --set cluster.kvBackend.address="$ETCD_ENDPOINTS"
    ```

* The installation process may take a few minutes.

#### Step 5 - Verifying Ondat Installation

* Run the following `kubectl` commands to inspect Ondat's resources (the core components should all be in a `RUNNING` status)

    ```bash
    kubectl get all --namespace=storageos
    kubectl get all --namespace=storageos-etcd  # only if the etcd cluster was deployed inside the Kubernetes cluster.
    kubectl get storageclasses | grep "storageos"
    ```

## Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Free Forever tier supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
