---
title: "Fencing"
linkTitle: Fencing
---

## StatefulSet behaviour

In order to understand what Ondat Fencing for Kubernetes is and when it is
needed, it is required to first understand the behaviour of StatefulSets.

[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
are the de facto Kubernetes controller to use for stateful applications. The
StatefulSet controller offers guarantees around pod uniqueness, sticky
identities and the persistence of PVCs beyond the lifetime of their pods. As
such, StatefulSets have different characteristics and provide different
guarantees than Deployments.

Deployments guarantee the amount of healthy replicas by reconciling towards the
deployment desired  state. Attempts to align the number of healthy pods with
the deployment's desired state happen as fast as possible by aggressively
initializing and terminating pods. If one pod is terminating, another will be
automatically scheduled to start even if the first pod is not yet completely
terminated. Stateless applications benefit from this behaviour as one pod
executes the same work as any other in the deployment.

StatefulSets, on the other hand, guarantee that every pod scheduled has a
unique identity, which is to say that only a single copy of a pod is running in
the cluster at any one time. Whenever scheduling decisions are made, the
StatefulSet controller ensures that only one copy of this pod is running at any
time. If a pod is deleted, a new pod will not be scheduled until the first pod
is fully terminated. This is an important guarantee as FileSystems need to be
unmounted before they can be remounted in a new pod. Any ReadWriteOnce PVC
defining a device requires this behaviour to ensure the consistency of the data
and thus the PVC.

To protect data integrity, Kubernetes guarantees that there will never be more
than one instance of a StatefulSet Pod running at a time. It assumes that when
a node is determined to be offline it may still be running the workload but
partitioned from the network. Since Kubernetes is unable to
verify that the Pod has been stopped it errs on the side of caution and does
not allow a replacement to start on another node.

Kubernetes does reschedule pods from some controllers when nodes become
unavailable. The default behaviour is that when a node becomes unavailable its
status becomes "Unknown" and after the `pod-eviction-timeout` has passed pods
are scheduled for deletion. By default, the `pod-eviction-timeout` is 300
seconds.

For this reason, Kubernetes requires manual intervention to initiate timely
failover of a StatefulSet Pod. The Ondat Fencing Controller gives the
capability to enable fast failover of workloads when a node goes offline.

For more information on the rationale behind the design of StatefulSets please
see the Kubernetes design proposal for [Pod
Safety](https://github.com/kubernetes/design-proposals-archive/blob/main/storage/pod-safety.md).

## Ondat Fencing Controller

> 💡 The Ondat Fencing Controller is part of the Ondat API Manager which
> is deployed in high availability when Ondat is installed.

__HA for StatefulSet applications can be achieved with the Ondat Fencing
feature__.

Since Ondat is able to determine when a node is no longer able to access a
volume and has protections in place to ensure that a partitioned or formerly
partitioned node can not continue to write data, it can work with Kubernetes to
perform safe, fast failovers of Pods, including those running in StatefulSets.

When Ondat detects that a node has gone offline or become partitioned, it
marks the node offline and performs volume failover operations.

The [Ondat Fencing
Controller](https://github.com/storageos/api-manager/tree/master/controllers/fencer)
watches for these node failures and determines if there are any pods assigned
to the failed node with the label `storageos.com/fenced=true`, and if the pods
have any PVCs backed by Ondat volumes.

When a Pod has Ondat volumes and if they are all healthy, the Ondat
fencing controller deletes the Pod to allow it to be rescheduled on another
node. It also deletes the VolumeAtachments for the corresponding volumes so
that they can be immediately attached to the new node.

No changes are made to Pods that have Ondat volumes that are unhealthy.
This is usually because a volume was configured to not have any replicas, and the
node with the single copy of the data is offline. In this case it is better to
wait for the node to recover.

Fencing works with both dynamically provisioned PVCs and PVCs referencing
pre-provisioned volumes.

The fencing feature is opt-in and Pods must have the
`storageos.com/fenced=true` label set, and be using at least one Ondat
volume, to enable fast failover.

For more information about how to enable pod fencing, see our [Fencing
Operations](/docs/operations/fencing) page.
