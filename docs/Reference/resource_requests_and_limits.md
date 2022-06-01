---
title: "Resource Requests and Limits"
linkTitle: Resource Requests and Limits
---

## Managing Resources for Ondat containers

Kubernetes resource requests and limits are two optional Pod properties that
allow you to specify how much of a resource a container in a Pod needs or can
use. They are two main resources that you can specify requests and limits for,
CPU and Memory.

As Ondat is an infrastructure component, the health of other applications
depends on being able to write to the Ondat volumes. As such it is of
paramount importance to avoid restarts of the Ondat DaemonSet Pods.
Restarting an Ondat Pod results in the volumes of the node the Ondat Pod
is running on being marked as Read Only, and causes the failover of primary
volumes on that node to their replicas. After an Ondat Pod restart, once the
Ondat DaemonSet Pod is "READY", the application Pods running on the node
need to be restarted in order to trigger a mount of the filesystem hosted on
the Ondat volume and resume normal operations. To avoid restarts of the
Ondat main container by Kubernetes due to resource limits being reached, it
is recommended to not set resource limits on the Ondat DaemonSet. In
addition to avoiding resource limits, Ondat uses a [high priority
class](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)
when the DaemonSet is installed in the 'storageos' namespace. That avoids the
DaemonSet Pods of being evicted.

For more information about managing resources for containers see the
[Kubernetes
documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

## Defining Pod resource requests and reservations

To add resource requests and reservations to the Ondat DaemonSet [configure them in the StorageOSCluster resource](/docs/reference/cluster-operator/examples#defining-pod-resource-requests-and-reservations).
