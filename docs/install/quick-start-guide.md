---
title: "Quick Start Guide"
linkTitle: "Quick Start Guide"
weight: 1
---

# Quick Start Guide - Non-Production

This guide will provide step by step instructions on how to install Ondat, with out helm chart, onto your cluster, for a non-production environment. 

> ⚠️ This guide is for a non-production installation. Please follow our [other installation guides](https://docs.ondat.io/docs/install/) for a production-ready installation of Ondat 

## Prerequisites

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [helm](https://helm.sh/docs/intro/install/)


This guide assumes you already have a Kubernetes cluster, with **at least** 3 worker nodes. 

### This guide has been tested on the following Kubernetes distributions
 - Rancher


## Step 1 - Install Ondat Helm Charts

Add the Ondat chart repo to Helm:

```bash
helm repo add ondat https://ondat.github.io/charts
helm repo update
```

## Step 2 - Install Local Path Provisioner

Etcd requires a storage class before we can start Ondat. For non-production environments the Local Path Provisioner storage class can be used.


```bash
kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
```

To verify that the Local Path Provisioner was successfully deployed and ensure that the deployment is in a  `RUNNING`  status, run the following  `kubectl`  commands.

```bash
kubectl get pod --namespace=local-path-storage
kubectl get storageclass
```

## Step 3 - Create the StorageOS namespace

```bash
kubectl create namespace storageos
```

## Step 4 - Customise and install the helm chart
We make a few changes to the default helm chart values, so we can run in smaller non-production sized clusters.

> ⚠️ Make sure to set the values of `ONDAT_USERNAME` and `ONDAT_PASSWORD`

```bash
export ONDAT_USERNAME="changeme"
export ONDAT_PASSWORD="changeme"

helm install ondat ondat/ondat --namespace storageos \
--set ondat-operator.cluster.admin.username=${ONDAT_USERNAME},\
ondat-operator.cluster.admin.password=${ONDAT_PASSWORD},\
etcd-cluster-operator.cluster.namespace=storageos,\
etcd-cluster-operator.cluster.replicas=3,\
etcd-cluster-operator.cluster.storageclass=local-path,\
etcd-cluster-operator.cluster.storage=6Gi,\
etcd-cluster-operator.cluster.resources.requests.cpu=100m,\
etcd-cluster-operator.cluster.resources.requests.memory=300Mi
```

## Step 5 - Set the default storage class

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass storageos -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Step 6 - Ensure everything is running

It can take a couple of minutes for the cluster to converge. A ready cluster will look like this:
```bash
kubectl -n storageos get pods,storageclass,poddisruptionbudget,svc

```
 <!-- TODO: add what a healthy cluster looks like  -->

## Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Community Edition tier supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
