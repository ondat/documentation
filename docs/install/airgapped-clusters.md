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
best to retrieve the yaml for the machine generated pipeline. To do so, the
following container prints it through stdout.

Run locally:
```
ONDAT_VERSION=v2.5.0
docker run --rm storageos/operator-manifests:$ONDAT_VERSION > ondat-operator.yaml
```

Or run in a k8s cluster:
```
ONDAT_VERSION=v2.5.0

# Once the image is pulled into your registry you can run
kubectl run operator-manifests --image storageos/operator-manifests:$ONDAT_VERSION 

# Get the yaml
kubectl logs operator-manifests > ondat-operator.yaml

# Clean
kubectl delete pod operator-manifests
```

Once you have the `ondat-operator.yaml` you must edit the file to amend the
container image URL for the private registry one. 
```
ONDAT_VERSION=v2.5.0
REGISTRY_IMG=my-registry-url/storageos/operator:$ONDAT_VERSION
sed -i -e "s#image: storageos/operator:$ONDAT_VERSION#image: $REGISTRY_IMG#g" operator-manifests.yaml
```

## 3. Define StorageOSCluster CR

## 4. (If Etcd in Kubernetes) Retrieve and amend the yaml for Etcd operator and Etcd CR

