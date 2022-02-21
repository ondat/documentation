---
title: "Kubectl plugin"
linkTitle: Kubectl plugin
---

Ondat has implemented a kubectl plugin to facilitate operations when
installing and interacting with Ondat clusters.

The kubectl plugin accepts both declarative and imperative modes.

## Install the storageos kubectl plugin

```
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.0.0/kubectl-storageos_1.0.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

## Examples

### Basic installation

```
kubectl storageos install
```

> 💡 The plugin will prompt you to get the url/s for etcd.

### Installation with custom username/password

Ondat uses a Kubernetes Secret to define the first admin user. You can define its credentials when installing.

```bash
kubectl storageos install \
    --admin-username "myuser" \
    --admin-password "my-password"
```

### Declarative installation

The Ondat kubectl plugin allows you to define the StorageOSCluster Custom
Resource declaratively, as a YAML. You can do this using one of the following options:

* Create a file `StorageOSCluster.yaml` with the Secret and StorageOSCluster CR:

    ```bash
    ---
    # Secret
    apiVersion: v1
    kind: Secret
    metadata:
      name: storageos-api
      namespace: storageos
      labels:
        app: storageos
    type: Opaque
    data:
      password: c3RvcmFnZW9z # echo -n <username> | base64
      username: c3RvcmFnZW9z # echo -n <username> | base64
    ---
    # CR cluster definition
    apiVersion: storageos.com/v1
    kind: StorageOSCluster
    metadata:
      name: storageos-cluster
      namespace: "storageos"
    spec:
      secretRefName: "storageos-api"
      k8sDistro: "upstream"
      storageClassName: "ondat" # The storage class created by the Ondat operator is configurable
      images:
        nodeContainer: "storageos/node:< param latest_node_version >"
        apiManagerContainer: storageos/api-manager:v2.5.0-sync
        initContainer: storageos/init:v2.1.0
        csiNodeDriverRegistrarContainer: quay.io/k8scsi/csi-node-driver-registrar:v2.1.0
        csiExternalProvisionerContainer: storageos/csi-provisioner:v2.1.1-patched
        csiExternalAttacherContainer: quay.io/k8scsi/csi-attacher:v3.1.0
        csiExternalResizerContainer: quay.io/k8scsi/csi-resizer:v1.1.0
        csiLivenessProbeContainer: quay.io/k8scsi/livenessprobe:v2.2.0
        kubeSchedulerContainer: k8s.gcr.io/kube-scheduler:v1.20.5
      kvBackend:
        address: "storageos-etcd-client.storageos-etcd:2379"
      resources:
        requests:
          memory: "1Gi"
          cpu: 1
    #  nodeSelectorTerms:
    #    - matchExpressions:
    #      - key: "node-role.kubernetes.io/worker" # Compute node label will vary according to your installation
    #        operator: In
    #        values:
    #        - "true"
    ```

   and install a cluster

    ```bash
   kubectl storageos install \
    --stos-cluster-yaml StorageOSCluster.yaml \
    --etcd-endpoints "storageos-etcd-client.storageos-etcd:2379"
    ```

* Create a YAML to describe the cluster's resources using a [Helm chart](https://github.com/storageos/charts/pull/129) or use the `kubectl plugin` with the `dry-run` flags enabled:

```bash
kubectl storageos install
    --dry-run
    --username c3RvcmFnZW9z
    --password c3RvcmFnZW9z
    --include-etcd ... 
```

  > Note, that when `--dry-run` is set for an install command, no installation takes place. Instead, the installation manifests that would have been installed under normal > circumstances are written locally to `./storageos-dry-run/`.

That generates YAML files that can be used in a GitOps pipeline (your installation is fully-declarative). At the end, the CI/CD tool runs `kubectl create -f ./path/to/yamls`.
