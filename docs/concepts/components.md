---
title: "Ondat Components"
linkTitle: "Ondat Components"
weight: 1
---

## Overview

Ondat is a software-defined storage platform for running stateful applications in Kubernetes.

Fundamentally, Ondat uses the storage attached to the nodes in the Ondat cluster to create and present virtual volumes into containers. 
- Space on the host is consumed from the mount point `/var/lib/storageos/data` - so it is recommended that [disk devices](https://en.wikipedia.org/wiki/Disk_storage) are used exclusively for Ondat, as described in the [Managing Host Storage](/docs/operations/managing-host-storage) operations page.

Ondat is agnostic to the underlying storage and runs equally well on bare metal, in virtual machines or on cloud providers.

![Ondat cluster Components Diagram](/images/docs/concepts/ondat-deployment.png)

Read about [the cloud native storage principles behind Ondat](https://www.ondat.io/platform/platform-overview).

## Kubernetes-native Ondat Components 

Ondat is architected as a series of containers that fulfil separate, discrete functions. 
- Below is a list of core Ondat components with a description for each components responsibilities & tasks:

### Ondat Cluster Operator

The [**Ondat Cluster Operator**](https://github.com/storageos/operator) is responsible for the creation and maintenance of the Ondat cluster. 
- This operator is primarily responsible for ensuring that all the relevant applications are running in your cluster.

### Ondat API Manager

The [**Ondat API Manager**](https://github.com/storageos/api-manager) acts as a middle-man between various APIs. It has all the capabilities of a [Kubernetes operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) and is also able to communicate with the Ondat control plane API.
- This application handles typical operator tasks like labelling or removing nodes from Ondat when removed from the Kubernetes. It is continually monitoring the state of the cluster and moving it towards the desired state when necessary.

### Ondat Data Plane

The **Ondat Data Plane** is responsible for all [I/O operations](https://en.wikipedia.org/wiki/Input/output) path related tasks; 
- [Reading](https://en.wikipedia.org/wiki/Reading_%28computer%29),
- [Writing](https://en.wikipedia.org/wiki/Read%E2%80%93write_memory), 
- [Compression](https://en.wikipedia.org/wiki/Data_compression),
- [Caching](https://en.wikipedia.org/wiki/Cache_%28computing%29).

### Ondat Control Plane

The **Ondat Control Plane** is responsible for monitoring and maintaining the state of volumes and nodes in the cluster. 
- The Control Plane and the Data Plane run together in a single container, managed by a daemonset. 
- The Control Plane works with a dedicated [`etcd`](https://etcd.io/) instance to maintain state consensus in your cluster.

### Ondat Scheduler

The **Ondat Scheduler** is responsible for scheduling applications on the same node as an application's
volumes.
- Ondat uses a custom [Kubernetes scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/) to handle pod placement, ensuring that volumes are deployed on the same nodes as the relevant workloads as often as possible.

### Ondat CSI Helper

The [**CSI Helper**](https://github.com/storageos/external-provisioner) is responsible for registering Ondat with Kubernetes as a CSI driver. 
- It is necessary because the internal persistent volume controller running in Kubernetes controller-manager does not have any direct interfaces to CSI drivers. 
- It monitors PVC objects created by users and creates/deletes volumes for them.

### Ondat Node Guard

The **Ondat Node Guard** is a key component of the [Ondat Rolling Upgrade Protection for Orchestrators](/docs/concepts/rolling-upgrades/) feature. It blocks certain nodes from being upgraded or drained thus avoiding data loss in the cluster.
- The Node Guard will detect if a volume is reconciling (for example, one that does not have enough synced replicas), at which point a node manager pod on the same node as the reconciling volume's master and replicas become unready. 
- Ondat uses a [PodDisruptionBudget (PDB)](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) to stop more than `1` node manager pod being unavailable at any point in time. This prevents the rolling upgrade from continuing until the PDB is satisfied and all volumes have fully reconciled.
- If the PDB is set to `1` and a Control Plane volume on a node is not ready for a long period of time, this will stop the upgrade process. The `api-managercomponent` will be able to dynamically set the PDB value if it can determine the health of the volume. 
- If the `api-managercomponent` knows that a volume will not be ready, it can increase the PDB `maxUnavailable` value, allowing the upgrade to continue. The Node Guard container will log when it is available to upgrade, it will also log the reason if upgrade is not possible.

> ⚠️ The Node Guard container only monitors volumes that host a deployment on its node (for example, it doesn’t care if a volume is unhealthy if the node it's running on hosts none of the volumes primary and replicas)

> ⚠️ There is some latency between a volume becoming unhealthy and the Node Guard noticing, due to the polling nature of both the `api-managercomponent` volume sync Kubernetes readiness endpoints)

### Ondat Node Manager

The **Ondat Node Manager** is an out-of-band pod used for node management. It runs on all nodes that run the `StorageOS` node container and is a separate pod so that it can be restarted independently of the node container.

## Putting It All Together

Ondat is deployed by the **Ondat Cluster Operator**. In Kubernetes, the Ondat **Control Plane** and **Data Plane** are deployed in a single pod managed by a [daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/). 
- This daemonset runs on every node in the cluster that will consume or present storage. 

The **Ondat Scheduler**, **CSI Helper**, **Cluster Operator** and **API Manager** run as separate [pods](https://kubernetes.io/docs/concepts/workloads/pods/) and are controlled as [deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Ondat is designed to feel familiar to Kubernetes users. Storage is managed through standard [StorageClasses](https://kubernetes.io/docs/concepts/storage/storage-classes/) , [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), and [Ondat features](/docs/concepts/labels) are controlled by [Kubernetes labels and selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/), prefixed with `storageos.com/`. 
- By default, volumes are cached to improve read performance and compressed to reduce network traffic.
- Any pod may mount an Ondat virtual volume from any node that is also running Ondat, regardless of whether the pod and volume are collocated on the same node. Therefore, applications may be started or restarted on any node and access volumes transparently.
