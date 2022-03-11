---
title: "Airgapped installation"
weight: 50
---

> The following page is for Advanced users. The full procedure is estimated to
> take ~60 minutes to complete.

Clusters without access to the internet require you to explicitly specify the
resources to be installed. To install Ondat on an airgapped cluster, you need
to do the following:

- Pull OCI images to private Docker registries.
- Retrieve and amend YAML for the Ondat cluster-operator and CRDs.
- Define the StorageOSCluster CustomResource YAML.
- (If applicable) Retrieve and amend YAML for Etcd operator and Etcd CustomResource.

## Step 1. Pulling images into a private registry

There are the following sets of images to pull:

- the Ondat operator image
- the images in the StorageOSCluster definition that define the images for each
  component of the cluster
- (if applicable) the images to run Etcd as Pods using the Etcd operator
  deployed by Ondat

1. Install the Ondat operator: `storageos/operator:v2.6.0` and `quay.io/brancz/kube-rbac-proxy:v0.10.0`
1. Pull the images from the list defined in the [storageos-related-images
  configMap](https://github.com/storageos/operator/blob/main/bundle/manifests/storageos-related-images_v1_configmap.yaml)
and select the branch for the release version.

    For instance for the branch `release-v2.5.0`:

    ```bash
    # Images to pull
    curl -s https://raw.githubusercontent.com/storageos/operator/release-v2.6.0/bundle/manifests/storageos-related-images_v1_configmap.yaml \
    | cut -d: -f2- \
    | grep ":v"
    ```

1. Pull the image `k8s.gcr.io/kube-scheduler:v1.21.5` with the tag
  matching your Kubernetes version. In this case k8s version `v1.21.5`.

1. If you are installing Etcd in Kubernetes, then pull
    - quay.io/coreos/etcd:v3.5.0
    - storageos/etcd-cluster-operator-controller:develop
    - storageos/etcd-cluster-operator-proxy:develop

> 💡 This page will follow the reference to the pulled images with the format
> `<url-of-registry>/<fqdn-of-public-image>:<tag>`, even though it is common to
> remove the qualified domain name from the image url in private registries
> leaving the URI of the image as `<user/image>:<tag>`. Set the URL for the
> images following the name pattern that suits your best practices. For
> example, the image `quay.io/k8scsi/csi-attacher:v3.1.0` is tranformed to
> `registry-service.registry.svc:5000/quay.io/k8scsi/csi-attacher:v3.1.0`

## Step 2. Retrieving the Cluster operator YAML

1. The Ondat operator YAMLs are generated for every release of the product. It
is best to retrieve the YAML from the machine-generated pipeline. To do so, run
locally the following container that prints them on stdout.

    ```bash
    ONDAT_VERSION=v2.6.0
    docker run   \
        --rm \
        storageos/operator-manifests:$ONDAT_VERSION > ondat-operator.yaml
    ```

    Or run in a k8s cluster:

    ```bash
    ONDAT_VERSION=v2.5.0

    # Once the image is pulled into your registry you can run
    kubectl run ondat-operator-manifests --image storageos/operator-manifests:$ONDAT_VERSION

    # Get the yaml
    kubectl logs ondat-operator-manifests > ondat-operator.yaml

    # Clean
    kubectl delete pod operator-manifests
    ```

1. Once you have the `ondat-operator.yaml` you must edit the file to amend the
container image URL for the private registry one.

    Edit the variables `REGISTRY_IMG_OPERATOR` and `REGISTRY_IMG_PROXY`

    ```bash
    # Change operator image for your registry url reference

    ONDAT_VERSION=v2.5.0
    REGISTRY_IMG_OPERATOR=my-registry-url/storageos/operator:$ONDAT_VERSION
    sed -i -e "s#image: storageos/operator:$ONDAT_VERSION#image: $REGISTRY_IMG_OPERATOR#g" ondat-operator.yaml

    REGISTRY_IMG_PROXY=my-registry-url/quay.io/brancz/kube-rbac-proxy:v0.10.0
    sed -i -e "s#image: quay.io/brancz/kube-rbac-proxy:v0.10.0#image: $REGISTRY_IMG_PROXY#g" ondat-operator.yaml

    # Check the change
    grep -C2 "image:" ondat-operator.yaml
    ```

## Step 3. Defining StorageOSCluster CR

The StorageOSCluster definition depends on your cluster. For all available
options, check the [operator
reference](/docs/reference/cluster-operator/configuration).
For airgapped clusters, it is important to note that `spec.images` section
needs to be populated with the images from the configMap from Step 1.

The file for the `ondat-cluster.yaml` should have the Secret called
`storageos-api` and the StorageOSCluster definition.

Edit the variable `REGISTRY` and change the `username` and `password` secret strings.

```yaml
# Set the registry URL
REGISTRY=my-registry-url

cat <<END > ondat-cluster.yaml
apiVersion: v1
kind: Secret
metadata:
  name: storageos-api
  namespace: storageos
  labels:
    app: storageos
type: Opaque
data:
  password: c3RvcmFnZW9z # echo -n storageos | base64
  username: c3RvcmFnZW9z # echo -n storageos | base64
---
# CR cluster definition
apiVersion: storageos.com/v1
kind: StorageOSCluster
metadata:
  name: storageos-cluster
  namespace: "storageos"
spec:
  secretRefName: "storageos-api"
  secretRefNamespace: "storageos"
  k8sDistro: "upstream"
  storageClassName: storageos
  images:
    nodeContainer: $REGISTRY/storageos/node:v2.6.0
    apiManagerContainer: $REGISTRY/storageos/api-manager:v1.2.2
    initContainer: $REGISTRY/storageos/init:v2.1.0
    csiNodeDriverRegistrarContainer: $REGISTRY/quay.io/k8scsi/csi-node-driver-registrar:v2.1.0
    csiExternalProvisionerContainer: $REGISTRY/storageos/csi-provisioner:v2.1.1-patched
    csiExternalAttacherContainer: $REGISTRY/quay.io/k8scsi/csi-attacher:v3.1.0
    csiExternalResizerContainer: $REGISTRY/quay.io/k8scsi/csi-resizer:v1.1.0
    csiLivenessProbeContainer: $REGISTRY/quay.io/k8scsi/livenessprobe:v2.2.0
    kubeSchedulerContainer: $REGISTRY/k8s.gcr.io/kube-scheduler:v1.21.5
  kvBackend:
    address: "storageos-etcd-client.storageos:2379"
#  nodeSelectorTerms:
#    - matchExpressions:
#      - key: "node-role.kubernetes.io/worker" # Compute node label will vary according to your installation
#        operator: In
#        values:
#        - "true"
END
```

> ⚠️  The `kubeSchedulerContainer` version depends on the Kubernetes version your
> cluster is running. In this example v1.21.5. Adjust the tag accordingly.

If you are using an external Etcd, skip Step 4.

## Step 4. (If Etcd in Kubernetes) Retrieving and amending the YAML for Etcd operator and Etcd CR

1. The YAMLs for Etcd are generated for every release of the product. It is
best to retrieve the YAML from the machine generated pipeline. To do so, run
the following container that prints them on stdout.

    ```bash
    ETCD_OPERATOR_VERSION=develop
    docker run   \
        --rm \
        storageos/etcd-cluster-operator-manifests:$ETCD_OPERATOR_VERSION > etcd-operator.yaml
    ```

    Or run in a k8s cluster:

    ```bash
    ETCD_OPERATOR_VERSION=develop

    # Once the image is pulled into your registry you can run
    kubectl run etcd-operator-manifests --image storageos/etcd-cluster-operator-manifests:develop

    # Get the yaml
    kubectl logs etcd-operator-manifests > etcd-operator.yaml

    # Clean
    kubectl delete pod etcd-operator-manifests
    ```

1. Once you have the `ondat-operator.yaml` you must edit the file to amend the
container image URL for the private registry one.

    Edit the variables `REGISTRY_IMG_ETCD_OPERATOR` and `REGISTRY_IMG_ETCD_PROXY`

    ```bash
    # Change the 2 images on the etcd-operator.yaml for your registry URL
    ETCD_OPERATOR_VERSION=develop
    REGISTRY_IMG_ETCD_OPERATOR=my-registry-url/storageos/etcd-cluster-operator-controller:$ETCD_OPERATOR_VERSION
    REGISTRY_IMG_ETCD_PROXY=my-registry-url/storageos/etcd-cluster-operator-proxy:$ETCD_OPERATOR_VERSION

    # Etcd operator controller image
    sed -i -e "s#image: storageos/etcd-cluster-operator-controller:$ETCD_OPERATOR_VERSION#image: $REGISTRY_IMG_ETCD_OPERATOR#g" etcd-operator.yaml

    # Etcd proxy operator
    sed -i -e "s#image: storageos/etcd-cluster-operator-proxy:$ETCD_OPERATOR_VERSION#image: $REGISTRY_IMG_ETCD_PROXY#g" etcd-operator.yaml

    # check the images are set correctly
    grep -C2 "image:" etcd-operator.yaml
    ```

1. Once the images are set on the `etcd-operator.yaml` it is required to add the
reqistry URL as an argument to the Etcd operator.

    Add the flag `-
    --etcd-repository=$REGISTRY/quay.io/coreos/etcd`  in
    the args of the `manager` container defined in `etcd-operator.yaml`

    Edit the variable `$REGISTRY`

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

1. Create the Etcd cluster definition, `etcd-cluster.yaml`.

    ```yaml
    apiVersion: etcd.improbable.io/v1alpha1
    kind: EtcdCluster
    metadata:
      name: storageos-etcd
    spec:
      version: 3.5.0
      podTemplate:
        affinity:
          podAntiAffinity:
            preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchExpressions:
                  - key: etcd.improbable.io/cluster-name
                    operator: In
                    values:
                    - storageos-etcd
                topologyKey: kubernetes.io/hostname
              weight: 100
        etcdEnv:
        - name: ETCD_HEARTBEAT_INTERVAL
          value: "500"
        - name: ETCD_ELECTION_TIMEOUT
          value: "5000"
        - name: ETCD_MAX_SNAPSHOTS
          value: "10"
        - name: ETCD_MAX_WALS
          value: "10"
        - name: ETCD_QUOTA_BACKEND_BYTES
          value: "8589934592"
        - name: ETCD_SNAPSHOT_COUNT
          value: "100000"
        - name: ETCD_AUTO_COMPACTION_RETENTION
          value: "20000"
        - name: ETCD_AUTO_COMPACTION_MODE
          value: revision
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 200m
            memory: 200Mi
      replicas: 3
      storage:
        volumeClaimTemplate:
          resources:
            requests:
              storage: 128Gi
          storageClassName: local-path # local files on host disk

      tls:
        enabled: false
        storageOSClusterNamespace: storageos
        storageOSEtcdSecretName: storageos-etcd-secret
    ```

## Step 5. Installing the cluster

Once all the YAMLs are ready, the Ondat cluster can be bootstrapped.

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
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    ```

1. Edit the variable `ETCD_STORAGECLASS`

    ```bash
    ETCD_STORAGECLASS=my-storage-class
    # Edit the StorageClass for etcd
    sed -i -e "s/storageClassName: local-path/storageClassName: $ETCD_STORAGECLASS/g" etcd-cluster.yaml
    ```

1. Edit the variable `ETCD_STORAGECLASS`

    ```bash
    # Install (the kubectl-storageos plugin installs Etcd and Ondat)
    ETCD_STORAGECLASS=my-storage-class
    ONDAT_VERSION=v2.5.0
    kubectl storageos install \
        --include-etcd \
        --etcd-storage-class $ETCD_STORAGECLASS \
        --etcd-namespace storageos \
        --etcd-operator-yaml etcd-operator.yaml \
        --etcd-cluster-yaml etcd-cluster.yaml \
        --skip-etcd-endpoints-validation \
        --stos-operator-yaml ondat-operator.yaml \
        --stos-cluster-yaml ondat-cluster.yaml \
        --stos-cluster-namespace storageos \
        --stos-version $ONDAT_VERSION
    ```

### Option 2: With external Etcd

1. Edit the variable `ETCD_URL`

    ```bash
    # Set etcd url
    # You can define multiple etcd urls separated by commas
    # http://peer1:2379,http://peer2:2379,http://peer3:2379
    ETCD_URL=http://etcd-url-or-ips:2379

    # Install
    ONDAT_VERSION=v2.6.0
    kubectl storageos install \
        --etcd-endpoints $ETCD_URL \
            --skip-etcd-endpoints-validation \
        --stos-operator-yaml ondat-operator.yaml \
        --stos-cluster-yaml ondat-cluster.yaml \
        --stos-cluster-namespace storageos \
        --stos-version $ONDAT_VERSION
    ```
