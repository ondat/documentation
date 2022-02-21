---
title: "Airgapped installation"
weight: 50
---


Clusters without access to the internet require to specifiy explicitly
resources that otherwise are automated during the installation.

- Pull OCI images to private docker registries
- Retrieve and amend yaml for the Ondat cluster-operator and CRDs
- Define the StorageOSCluster CustomResource yaml
- (If apply) Retrieve and amend yaml for Etcd operator and Etcd CustomResource

## 1. Images to pull into a private registry 

There are 3 sets of images to pull, the Ondat operator image, the Images
defined in the StorageOSCluster definition that define the images for each
component of the cluster and, if apply, the images to run Etcd as Pods using
the Etcd operator deployed by Ondaat. 

- Ondat operator: `storageos/operator:v2.5.0`
- Get the image list from the
  [storageos-related-images configMap](https://github.com/storageos/operator/blob/main/bundle/manifests/storageos-related-images_v1_configmap.yaml)
and select the branch for the version release of Ondat to be installed.
- If you are installing Etcd in Kubernetes, then pull 
	- quay.io/coreos/etcd:v3.5.0
	- storageos/etcd-cluster-operator-controller:develop
	- storageos/etcd-cluster-operator-proxy:develop


## 2. Cluster operator yaml

The Ondat operator yamls are generated for every release of the product. It is
best to retrieve the yaml from the machine generated pipeline. To do so, the
following container prints them on stdout.

Run locally:
```
ONDAT_VERSION=v2.5.0
docker run --rm storageos/ondat-operator-manifests:$ONDAT_VERSION > ondat-operator.yaml
```

Or run in a k8s cluster:
```
ONDAT_VERSION=v2.5.0

# Once the image is pulled into your registry you can run
kubectl run ondat-operator-manifests --image storageos/operator-manifests:$ONDAT_VERSION 

# Get the yaml
kubectl logs ondat-operator-manifests > ondat-operator.yaml

# Clean
kubectl delete pod operator-manifests
```

Once you have the `ondat-operator.yaml` you must edit the file to amend the
container image URL for the private registry one. 
```
# Change operator image for your registry url reference

ONDAT_VERSION=v2.5.0
REGISTRY_IMG=my-registry-url/storageos/operator:$ONDAT_VERSION
sed -i -e "s#image: storageos/operator:$ONDAT_VERSION#image: $REGISTRY_IMG#g" operator-manifests.yaml
```

## 3. Define StorageOSCluster CR

The StorageOSCluster definition depends on your cluster. Check the [operator
reference](docs/reference/cluster-operator/configuration) for all the options
available. For airgapped clusters, it is important to note the `spec.images`
section that needs to be populated with the images from the configMap seen on step 1. 

The file for the `ondat-cluster.yaml` should have the Secret called
`storageos-api` and the StorageOSCluster definition.


```yaml
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
  secretRefNamespace: "storageos"
  k8sDistro: "upstream"
  storageClassName: storageos
  images:
    nodeContainer: "storageos/node:v2.5.0
    apiManagerContainer: storageos/api-manager:v1.2.2
    initContainer: storageos/init:v2.1.0
    csiNodeDriverRegistrarContainer: quay.io/k8scsi/csi-node-driver-registrar:v2.1.0
    csiExternalProvisionerContainer: storageos/csi-provisioner:v2.1.1-patched
    csiExternalAttacherContainer: quay.io/k8scsi/csi-attacher:v3.1.0
    csiExternalResizerContainer: quay.io/k8scsi/csi-resizer:v1.1.0
    csiLivenessProbeContainer: quay.io/k8scsi/livenessprobe:v2.2.0
    kubeSchedulerContainer: k8s.gcr.io/kube-scheduler:v1.21.5
  kvBackend:
    address: "storageos-etcd-client.storageos:2379"
#  nodeSelectorTerms:
#    - matchExpressions:
#      - key: "node-role.kubernetes.io/worker" # Compute node label will vary according to your installation
#        operator: In
#        values:
#        - "true"
```

> ⚠️  The `kubeSchedulerContainer` version depends on the Kubernetes version your
> cluster is running. In this example v1.21.5. Adjust the tag accordingly. 

If you are using an external Etcd, skip step 4.

## 4. (If Etcd in Kubernetes) Retrieve and amend the yaml for Etcd operator and Etcd CR

The yamls for etcd are generated for every release of the product. It is
best to retrieve the yaml from the machine generated pipeline. To do so, the
following container prints them on stdout.


Run locally:
```
ETCD_OPERATOR_VERSION=develop
docker run etcd-operator-manifests --rm storageos/operator-manifests:$ETCD_OPERATOR_VERSION > etcd-operator.yaml
```

Or run in a k8s cluster:
```
ETCD_OPERATOR_VERSION=develop

# Once the image is pulled into your registry you can run
kubectl run etcd-operator-manifests --image storageos/etcd-cluster-operator-manifests:develop

# Get the yaml
kubectl logs etcd-operator-manifests > etcd--operator.yaml

# Clean
kubectl delete pod etcd-operator-manifests
```

Once you have the `ondat-operator.yaml` you must edit the file to amend the
container image URL for the private registry one. 

```
# Change the 2 images on the etcd-operator.yaml for your registry URL
ETCD_OPERATOR_VERSION=develop

# Etcd operator controller image
REGISTRY_IMG_ETCD_OPERATOR=my-registry-url/storageos/etcd-operator:$ETCD_OPERATOR_VERSION
sed -i -e "s#image: storageos/etcd-cluster-operator-controller:$ETCD_OPERATOR_VERSION#image: $REGISTRY_IMG_ETCD_OPERATOR#g" etcd-operator.yaml

REGISTRY_IMG_ETCD_PROXY=my-registry-url/storageos/etcd-proxy:$ETCD_OPERATOR_VERSION
sed -i -e "s#image: storageos/etcd-cluster-operator-proxy:$ETCD_OPERATOR_VERSION#image: $REGISTRY_IMG_ETCD_PROXY#g" etcd-operator.yaml

# check the images are set correctly
grep -C2 "image:" etcd-operator.yaml
```

Create the Etcd cluster definition, `etcd-cluster.yaml`.

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
      storageClassName: local-path
  tls:
    enabled: false
    storageOSClusterNamespace: storageos
    storageOSEtcdSecretName: storageos-etcd-secret
```


## 5. Install the cluster

Once all the yamls are ready, the Ondat cluster can be bootstrapped. 

### Option 1: With etcd in Kubernetes

The etcd cluster in Kubernetes requires an StorageClass. If you are running on
a cloud provider, you can use existing StorageClasses for it, i.e gp3 (AWS) or
standard (GCE). Or you can create the local-path StorageClass. It is
recommended to give etcd a backend disk that can sustain at least 800 IOPS. It
is best to use provisioned IOPS when possible, otherwise make sure the size of
the disk is big enough to fulfil the IOPS requirement when performance depends
on IOPS per GB.  For instance, AWS would require a burstable EBS bigger than
256G to fulfil the IOPS requirement.  

⚠️  The `local-path` StorageClass is only recommended for non production
clusters as the data of the etcd peers is susceptible of being lost on node
failure.

```bash
# Local-path StorageClass
# Not for production workloads
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

```bash
ETCD_STORAGECLASS=my-storage-class
# Edit the StorageClass for etcd
sed -i -e "s/storageClassName: local-path/storageClassName: $ETCD_STORAGECLASS/g" etcd-cluster.yaml
```


```
# Install (plugin installs Etcd and Ondat)
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

### Option 2: With external etcd

```
# Set etcd url
# You can define multiple etcd urls separated by commas
# http://peer1:2379,http://peer2:2379,http://peer3:2379
ETCD_URL=http://etcd-url-or-ips:2379 

# Install
ONDAT_VERSION=v2.5.0
kubectl storageos install \
	--etcd-endpoints $ETCD_URL \
	--stos-operator-yaml ondat-operator.yaml \
	--stos-cluster-yaml ondat-cluster.yaml \
	--stos-cluster-namespace storageos \
	--stos-version $ONDAT_VERSION
```
