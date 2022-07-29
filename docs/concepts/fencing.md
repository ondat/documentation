---
title: "Ondat Fencing"
linkTitle: "Ondat Fencing"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.4.0` or greater.

### What Is Ondat Fencing?

In order to understand what Ondat Fencing for Kubernetes is and when it is needed, it is required to first understand the behaviour of [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

*StatefulSets* are the de facto Kubernetes controller to use for stateful applications. The StatefulSet controller offers guarantees around pod uniqueness, sticky identities and the persistence of PVCs beyond the lifetime of their pods.

- As such, StatefulSets have different characteristics and provide different guarantees than [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

*Deployments* guarantee the amount of healthy replicas by reconciling towards the deployment desired state. Attempts to align the number of healthy pods with the deployment's desired state happen as fast as possible by aggressively initialising and terminating pods.

- If one pod is terminating, another will be automatically scheduled to start even if the first pod is not yet completely terminated. Stateless applications benefit from this behaviour as one pod executes the same work as any other in the deployment.

StatefulSets, on the other hand, **guarantee that every pod scheduled has a unique identity**, which is to say that only a single copy of a pod is running in the cluster at any one time.

- Whenever scheduling decisions are made, the StatefulSet controller ensures that only one copy of this pod is running at any time.
- If a pod is deleted, a new pod will not be scheduled until the first pod is fully terminated. This is an important guarantee as file systems need to be unmounted before they can be remounted in a new pod. Any [ReadWriteOnce (RWO)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) PVC defining a device requires this behaviour to ensure the consistency of the data and thus the PVC.

To protect data integrity, Kubernetes guarantees that there will never be more than one instance of a StatefulSet pod running at a time. It assumes that when a node is determined to be offline it may still be running the workload but partitioned from the network. Since Kubernetes is unable to verify that the pod has been stopped it errors on the side of caution and does not allow a replacement to start on another node.

Kubernetes does reschedule pods from some controllers when nodes become unavailable. The default behaviour is that when a node becomes unavailable its status becomes `Unknown` and after the `pod-eviction-timeout` has passed pods are scheduled for deletion. By default, the `pod-eviction-timeout` is `300` seconds.

- For this reason, Kubernetes requires manual intervention to initiate timely failover of a StatefulSet pod. The **Ondat Fencing Controller** gives the capability to enable fast failover for workloads when a node goes offline.

For more information on the rationale behind the design of StatefulSets, review the Kubernetes design proposal archive for [Pod Safety, Consistency Guarantees, and Storage Implications](https://github.com/kubernetes/design-proposals-archive/blob/main/storage/pod-safety.md).

### Ondat Fencing Controller

> 💡 The Ondat Fencing Controller is part of the Ondat API Manager which is deployed in high availability mode when Ondat is installed.

> 💡 High Availability for StatefulSet applications can be achieved with the Ondat Fencing feature.

Since Ondat is able to determine when a node is no longer able to access a volume and has protections in place to ensure that a partitioned or formerly partitioned node can stop writing data, it can work with Kubernetes to perform safe, fast failovers of pods, including those running in StatefulSets.

- When Ondat detects that a node has gone offline or become partitioned, it marks the node offline and performs volume failover operations.

The [Ondat Fencing Controller](https://github.com/storageos/api-manager/tree/master/controllers/fencer) watches for these node failures and determines if there are any pods assigned to the failed node with the label `storageos.com/fenced=true`, and if the pods have any PVCs backed by Ondat volumes.

- When a pod has Ondat volumes and if they are all healthy, the Ondat Fencing Controller deletes the pod to allow it to be rescheduled on another node. It also deletes the `VolumeAttachment` object for the corresponding volumes so that they can be immediately attached to the new node.
- No changes are made to pods that have Ondat volumes that are unhealthy. This is usually because a volume was configured to not have any replicas, and the node with the single copy of the data is offline. In this case it is better to wait for the node to recover.

Ondat Fencing works with both dynamically provisioned PVCs and PVCs referencing pre-provisioned volumes.

- In addition, the fencing feature is opt-in and pods must have the `storageos.com/fenced=true` label set, and be using at least one Ondat volume, to enable fast failover.

For more information about how to enable Ondat fencing, review the [Ondat Fencing](/docs/operations/fencing) operations page.
