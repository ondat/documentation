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

The Ondat kubectl plugin allows to define the StorageOSCluster Custom
Resource declaratively, as a yaml.

1. Create a file `StorageOSCluster.yaml` with the Secret and StorageOSCluster CR

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
        apiManagerContainer: storageos/api-manager:v1.2.2
        initContainer: storageos/init:v2.1.0
        csiNodeDriverRegistrarContainer: quay.io/k8scsi/csi-node-driver-registrar:v2.1.0
        csiExternalProvisionerContainer: storageos/csi-provisioner:v2.1.1-patched
        csiExternalAttacherContainer: quay.io/k8scsi/csi-attacher:v3.1.0
        csiExternalResizerContainer: quay.io/k8scsi/csi-resizer:v1.1.0
        csiLivenessProbeContainer: quay.io/k8scsi/livenessprobe:v2.2.0
        kubeSchedulerContainer: k8s.gcr.io/kube-scheduler:v1.21.5
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

1. Install cluster

    ```bash
    kubectl storageos install --stos-cluster-yaml StorageOSCluster.yaml --etcd-endpoints "storageos-etcd-client.storageos-etcd:2379"
    ```
