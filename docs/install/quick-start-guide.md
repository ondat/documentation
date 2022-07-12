---
title: "Quick Start Guide"
linkTitle: "Quick Start Guide"
weight: 1
---

# Quick Start Guide - Non-Production

This guide will provide step by step instructions on how to install Ondat onto your cluster, with our helm chart, for a non-production environment. 

> ⚠️ This guide is for a non-production installation. Please follow our [other installation guides](https://docs.ondat.io/docs/install/) for a production-ready installation of Ondat 

## Prerequisites

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [helm](https://helm.sh/docs/intro/install/)


This guide assumes you already have a Kubernetes cluster, with **at least** 3 worker nodes. 

### This guide has been tested on the following Kubernetes distributions
 - Vanilla Kubernetes
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

The following command can be used to ensure the Local Path Provisioner was successfully deployed. The expected output is also shown

```bash
> kubectl get pod,storageclass --namespace=local-path-storage
NAME                                         READY   STATUS    RESTARTS   AGE
pod/local-path-provisioner-c4d687f4c-bxmjt   1/1     Running   0          3h10m

NAME                                     PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
storageclass.storage.k8s.io/local-path   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  3h10m
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
etcd-cluster-operator.cluster.namespace=storageos-etcd,\
etcd-cluster-operator.cluster.replicas=3,\
etcd-cluster-operator.cluster.storageclass=local-path,\
etcd-cluster-operator.cluster.storage=6Gi,\
etcd-cluster-operator.cluster.resources.requests.cpu=100m,\
etcd-cluster-operator.cluster.resources.requests.memory=300Mi
```

## Step 5 - Wait until the storageos storage class has been created

It can take a few seconds for the storageos storage class to be created. We need to wait for this before we can set it as the default storage class.

The following command can be used to ensure the storageos storage class was successfully deployed. The expected output is also shown

```bash 
> kubectl -n storageos get storageclass -w
NAME         PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  3h4m
storageos    csi.storageos.com       Delete          Immediate              true                   75m
```

## Step 6 - Set the default storage class

Set the storageos storage class as the default

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass storageos -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```


## Step 7 - Ensure everything is running

It can take a couple of minutes for the cluster to converge. A ready cluster will look like this:
```bash
> kubectl -n storageos get pods,storageclass,svc                    
NAME                                           READY   STATUS    RESTARTS      AGE
pod/ondat-controller-manager-5f7f669b4-fqj57   1/1     Running   0             73m
pod/ondat-controller-manager-5f7f669b4-jmbfk   1/1     Running   0             73m
pod/ondat-ondat-operator-675c4c9c88-9jgrv      2/2     Running   0             73m
pod/ondat-proxy-6887466cd5-vlkq6               1/1     Running   0             73m
pod/storageos-api-manager-6677c95579-qdght     1/1     Running   0             71m
pod/storageos-api-manager-6677c95579-rzwqr     1/1     Running   1 (71m ago)   71m
pod/storageos-csi-helper-6fbb8cc7d9-h767k      4/4     Running   0             71m
pod/storageos-node-fmtrd                       3/3     Running   3 (72m ago)   72m
pod/storageos-node-h54xp                       3/3     Running   3 (72m ago)   72m
pod/storageos-node-jm5th                       3/3     Running   3 (72m ago)   72m
pod/storageos-scheduler-664886b7b-8jrv2        1/1     Running   0             72m

NAME                                     PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
storageclass.storage.k8s.io/local-path   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  3h1m
storageclass.storage.k8s.io/storageos    csi.storageos.com       Delete          Immediate              true                   72m

NAME                                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/ondat-proxy                     ClusterIP   10.100.222.57    <none>        80/TCP     73m
service/storageos                       ClusterIP   10.102.114.114   <none>        5705/TCP   72m
service/storageos-api-manager-metrics   ClusterIP   10.105.234.54    <none>        8080/TCP   71m
service/storageos-operator              ClusterIP   10.109.66.235    <none>        8443/TCP   73m
service/storageos-operator-webhook      ClusterIP   10.103.117.39    <none>        443/TCP    73m
service/storageos-webhook               ClusterIP   10.108.126.126   <none>        443/TCP    71m

```

```bash
> kubectl -n storageos-etcd get pods,pdb
NAME                         READY   STATUS    RESTARTS   AGE
pod/storageos-etcd-0-jbmq6   1/1     Running   0          73m
pod/storageos-etcd-1-nhbk6   1/1     Running   0          72m
pod/storageos-etcd-2-n9b9w   1/1     Running   0          72m

NAME                                        MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/storageos-etcd   2               N/A               1                     73m
```

## Applying a Licence to the Cluster

> ⚠️ Newly installed Ondat clusters must be licensed within 24 hours. Our Community Edition tier supports up to 1 TiB of provisioned storage.

To obtain a licence, follow the instructions on our [licensing operations](/docs/operations/licensing) page.
