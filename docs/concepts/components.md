---
title: "Ondat Components"
linkTitle: "Ondat Components"
---

# Overview

Ondat is a software-defined storage platform for running stateful applications in Kubernetes.

Fundamentally, Ondat uses the storage attached to the nodes in the Ondat cluster to create and present virtual volumes into containers. Space on the host is consumed from the mount point `/var/lib/storageos/data`, so it is therefore recommended that disk devices are used exclusively for Ondat, as described in [Managing Host Storage](/docs/operations/managing-host-storage)

Ondat is agnostic to the underlying storage and runs equally well on
bare metal, in virtual machines or on cloud providers.

![Ondat cluster components](/images/docs/concepts/ondat-cluster.png)

Read about [the cloud native storage principles behind
Ondat](https://www.ondat.io/platform/platform-overview).

# Ondat on Kubernetes

Ondat is architected as a series of containers that fulfil separate,
discrete functions.

Links where appropriate have been given to our open-source GitHub repository.

## [Ondat Cluster Operator](https://github.com/storageos/operator)

Responsible for the creation and maintenance of the Ondat cluster. This
operator is primarily responsible for ensuring that all the relevant
applications are running in your cluster.

## Ondat Controlplane

Responsible for monitoring and maintaining the state of volumes and nodes
in the cluster. The Controlplane and the Dataplane run together in a single
container, managed by a daemonset. The Controlplane works with etcd to maintain
state consensus in your cluster.

## Ondat Dataplane

Responsible for all I/O path related tasks; reading, writing, compression
and caching.

## Ondat Scheduler

Responsible for scheduling applications on the same node as an application's
volumes. Ondat uses a custom Kubernetes scheduler to handle pod placement,
ensuring that volumes are deployed on the same nodes as the relevant workloads
as often as possible.

## [CSI helper](https://github.com/storageos/external-provisioner)

Responsible for registering Ondat with Kubernetes as a CSI driver. It
is necessary because the internal persistent volume controller running in
Kubernetes controller-manager does not have any direct interfaces to CSI
drivers. It monitors PVC objects created by users and creates/deletes volumes
for them.

## [Ondat API manager](https://github.com/storageos/api-manager)

Acts as a middle-man between various APIs. It has all the capabilities of a
Kubernetes Operator and is also able to communicate with the Ondat control
plane API. This application handles typical operator tasks like labelling or
removing nodes from Ondat when removed from the Kubernetes. It is
continually  monitoring the state of the cluster and moving it towards the
desired state when necessary.

Ondat is deployed by the Ondat Cluster Operator. In Kubernetes, the
Ondat Controlplane and Dataplane are deployed in a single pod managed by a
daemonset.  This daemonset runs on every node in the cluster that will consume
or present storage. The Scheduler, CSI helper, Cluster Operator and API Manager
run as separate pods and are controlled as deployments.

Ondat is designed to feel familiar to Kubernetes and Docker users. Storage
is managed through standard StorageClasses and PersistentVolumeClaims, and
[features](/docs/reference/labels) are controlled by
Kubernetes-style labels and selectors, prefixed with `storageos.com/`. By
default, volumes are cached to improve read performance and compressed to
reduce network traffic.

Any pod may mount an Ondat virtual volume from any node that is also
running Ondat, regardless of whether the pod and volume are
collocated on the same node. Therefore, applications may be started or
restarted on any node and access volumes transparently.

## Ondat Upgrade Guard

The upgrade guard is a key component of the rolling upgrade feature. It blocks certain nodes from being upgraded or drained thus avoiding data loss in the cluster.

The upgrade guard will detect if a volume is reconciling (for example, one that does not have enough synced replicas), at which point a node manager pod on the same node as the reconciling volume's master and replicas become unready. Ondat uses a PodDisruptionBudget (PDB) to stop more than 1 node manager pod being unavailable at any point in time. This prevents the rolling upgrade from continuing until the PDB is satisfied and all volumes have fully reconciled

If the PDB is set to 1 and a Control Plane volume on a node is not ready for a long period of time, this will stop the upgrade process. The `api-managercomponent` will be able to dynamically set the PDB value if it can determine the health of the volume. If the `api-managercomponent` knows that a volume will not be ready, it can increase the PDB `maxUnavailable` value, allowing the upgrade to continue. The upgrade guard container will log when it is available to upgrade, it will also log the reason if upgrade is not possible.

>⚠️ The upgrade guard container only monitors volumes that host a deployment on its node (for example, it doesn’t care if a volume is unhealthy if the node it's running on hosts none of the volumes primary and replicas)

>⚠️ There is some latency between a volume becoming unhealthy and the upgrade guard noticing, due to the polling nature of both the `api-managercomponent` volume sync Kubernetes readiness endpoints)

## Ondat Node Manager

The Node manager is an out-of-band pod used for node management.  It runs on all nodes that run the `StorageOS` node container and is a separate pod so that it can be restarted independently of the node container.
