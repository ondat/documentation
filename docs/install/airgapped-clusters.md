---
title: "Airgapped installation"
weight: 50
---

> The following page is for advanced users. The full procedure is estimated to
> take ~60 minutes to complete.

Clusters without access to the internet require you to explicitly specify the
resources to be installed. For that reason the `storageos` kubectl plugin
`--dry-run` flag generates all the yamls for your cluster. You can amend them
with the images pulled to your private registry. To install Ondat on an
airgapped cluster, you need

- Install the `storageos` kubectl plugin
- Generate yaml manifests and amend for your use case
- Pull OCI images to private registries.
- Install Ondat on your cluster

There are the following sets of images to pull that will be shown along the
following steps.

- the Ondat operator image
- the images in the StorageOSCluster definition that define the images for each
  component of the cluster
- (if applicable) the images to run Etcd as Pods using the Etcd operator
  deployed by Ondat

## Step 1. Install storageos kubectl plugin

```bash
curl -sSLo kubectl-storageos.tar.gz \
    https://github.com/storageos/kubectl-storageos/releases/download/v1.1.0/kubectl-storageos_1.1.0_linux_amd64.tar.gz \
    && tar -xf kubectl-storageos.tar.gz \
    && chmod +x kubectl-storageos \
    && sudo mv kubectl-storageos /usr/local/bin/ \
    && rm kubectl-storageos.tar.gz
```

> 💡 You can find binaries for different architectures and systems in [kubectl
> plugin](https://github.com/storageos/kubectl-storageos/releases).

## Step 2. Generate yaml manifests

### Option 1: With Etcd in Kubernetes

The etcd cluster in Kubernetes requires a StorageClass. If you are running on a
cloud provider, you can use existing StorageClasses for it, for example `gp3`
(AWS) or `standard` (GCE). Or you can create the `local-path` StorageClass.
It's recommended to give Etcd a backend disk that can sustain at least 800
IOPS. It's best to use provisioned IOPS when possible, otherwise make sure the
size of the disk is big enough to fulfil the IOPS requirement when performance
depends on IOPS per GB.  For example, AWS would require a burstable EBS bigger
than 256G to fulfil the IOPS requirement.

1. Create StorageClass (if you don't have one available)

    > ⚠️  The `local-path` StorageClass is only recommended for __non production__
    clusters as the data of the etcd peers is susceptible to being lost on node
    failure.

    ```bash
    # Local-path StorageClass
    # Not for production workloads

    # Pull yaml
    curl -SsLo local-path.yaml https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

    # Pull the following images into your registry
    grep "image:" local-path.yaml

    # Add registry URL to the image
    vi local-path.yaml
    ...

    # Create the storageclass
    kubectl apply -f local-path.yaml
    ```

1. Generate yaml manifests
    > The following command generates a directory called `storageos-dry-run`
    > with the manifests.

    ```bash
    # Generate yamls
    ETCD_STORAGECLASS=my-storage-class
    ONDAT_VERSION=v2.6.0
    K8S_VERSTION=v1.22.6
    USERNAME=storageos
    PASSWORD=storageos

    kubectl storageos install \
        --include-etcd \
        --etcd-storage-class $ETCD_STORAGECLASS \
        --skip-etcd-endpoints-validation \
        --k8s-version $K8S_VERSION \
        --admin-username "$USERNAME" \
        --admin-password "$PASSWORD" \
        --dry-run
    ```

1. Amend the file `etcd-operator.yaml`

    ```bash
    cd storageos-dry-run
    vi etcd-operator.yaml
    ...
    ```

    Edit the file `etcd-operator.yaml` and change:
    - Find the 2 deployments `storageos-etcd-controller-manager` and
      `storageos-etcd-proxy` and edit the images to set the registry url
      prefix.
    - Add the flag `--etcd-repository=$REGISTRY/quay.io/coreos/etcd`  in the
      args of the `manager` container.

        For example:

        ```bash
        REGISTRY=my-registry-url
        # Old
              - args:
                - --enable-leader-election
                - --proxy-url=storageos-proxy.storageos-etcd.svc
                command:
                - /manager

        # New
              - args:
                - --enable-leader-election
                - --proxy-url=storageos-proxy.storageos-etcd.svc
                - --etcd-repository=$REGISTRY/quay.io/coreos/etcd # Edit this line with your registry url
                command:
                - /manager
        ```

1. Amend the file `etcd-cluster.yaml`

    ```bash
    vi etcd-cluster.yaml
    ...
        volumeClaimTemplate:
          resources:
            requests:
              storage: 256Gi
    ...
    ```

    Define the `storge` size of the Etcd volumes. The backend disk requires at
    least 800 IOPS for etcd to work normally. If you are on a cloud provider
    that enables IOPSxGB, it is recommended to use a big enough volume. For
    instance, on AWS a 256GiB or a 50GiB GCE SSD persistent disk.

### Option 2: With external Etcd

1. Generate yaml manifests

    > The following command generates a directory called `storageos-dry-run`
    > with the manifests.

    ```bash
    # Set etcd url
    # You can define multiple etcd urls separated by commas
    # http://peer1:2379,http://peer2:2379,http://peer3:2379
    ETCD_URL=http://etcd-url-or-ips:2379

    # Generate yamls
    ETCD_STORAGECLASS=my-storage-class
    ONDAT_VERSION=v2.6.0
    K8S_VERSTION=v1.22.6
    USERNAME=storageos
    PASSWORD=storageos

    kubectl storageos install \
        --etcd-endpoints $ETCD_URL \
        --skip-etcd-endpoints-validation \
        --k8s-version $K8S_VERSION \
        --admin-username "$USERNAME" \
        --admin-password "$PASSWORD" \
        --dry-run
    ```

## Step 3. Amend manifests

1. Amend the file `storageos-operator.yaml`

    ```bash
    cd storageos-dry-run
    vi storageos-operator.yaml
    ```

    Edit the file `storageos-operator.yaml` and change:
    - Find the `ConfigMap` called `storageos-related-images` and change the
      URLs of the images adding your registry URL prefix.
    - Find the `Deployment` called `storageos-operator` and change the `images`
      of the 2 containers on it adding your registry URL prefix. They are the
      containers `manager` and `kube-rbac-proxy`.

1. (Optional) Amend the file `storageos-cluster.yaml`
    The StorageOSCluster definition depends on your cluster. For all available
    options, check the [operator
    reference](/docs/reference/cluster-operator/configuration). You can add
    options such as tolerations, nodeSelectors, etc.

## Step 4. Pulling images into a private registry

The images set on the previous steps need to be added to your registry.

```bash
grep -E  "RELATED|image:" *.yaml
```

## Step 5. Install Ondat

```bash
# Create the operators and CRDs first
find . -name '*-operator.yaml'  | xargs -I{} kubectl create -f {}

# Create the CustomResources
find . -name '*-cluster.yaml'  | xargs -I{} kubectl create -f {}
```

## Verify the installation

1. Etcd

    ```bash
    $ kubectl -n storageos-etcd get pod
    NAME                                                READY   STATUS    RESTARTS   AGE
    storageos-etcd-0-l4scc                              1/1     Running   0          2m19s
    storageos-etcd-1-mzrv7                              1/1     Running   0          2m19s
    storageos-etcd-2-bq596                              1/1     Running   0          2m19s
    storageos-etcd-controller-manager-f89d9dc47-dlvgb   1/1     Running   0          2m34s
    storageos-etcd-proxy-55479b544c-qm6nf               1/1     Running   0          2m34s
    ```

2. Ondat

    ```bash
    $ kubectl -n storageos get pod
    NAME                                     READY   STATUS    RESTARTS        AGE
    storageos-api-manager-54df545cbf-fn9cq   1/1     Running   0               113s
    storageos-api-manager-54df545cbf-vmc56   1/1     Running   1 (106s ago)    113s
    storageos-csi-helper-65db657d7c-52rkj    3/3     Running   0               115s
    storageos-node-v6tbg                     3/3     Running   2 (2m17s ago)   2m30s
    storageos-node-wg9rq                     3/3     Running   2 (2m18s ago)   2m30s
    storageos-node-zhhkz                     3/3     Running   2 (2m17s ago)   2m30s
    storageos-operator-6fc687d97b-fjqhd      2/2     Running   0               2m55s
    storageos-scheduler-7d66d44694-6n99d     1/1     Running   0               2m38s
    ```

    > The `storageos-node` damonset pods will restart until they can connect to
    > etcd

## Step 6. Licese the cluster

A cluster can operate without a licence for 24h. Follow the
[licensing](/docs/operations/licensing/) page to apply a licence to your cluster.
