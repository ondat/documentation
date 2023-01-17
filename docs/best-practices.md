---
title: Ondat Best Practices
linkTitle: Best Practices
weight: 450
---

## Etcd - In Cluster - Replicas and Availability Zones

We recommend running etcd with 5 replicas (etcd peers) and spreading them across availability zones when running etcd inside the cluster, this improves the resiliency of the etcd cluster. This is done by default when installing via the plugin or helm.

## Etcd low latency IO

It is recommended to run etcd on low-latency disks and keep other IO-intensive
applications separate from the etcd nodes. Etcd is very sensitive to IO latency.
Thus, the effect of disk contention can cause etcd downtime.

Batch jobs such as backups, builds or application bundling can easily cause a
high usage of disks making etcd unstable. It is recommended to run such
workloads apart from the etcd servers.

## Setup of storage on the hosts

We recommend creating a separate filesystem for Ondat to mitigate the risk
of filling the root filesystem on nodes. This has to be done for each node in
the cluster.

Follow the [managing host storage](/docs/operations/managing-host-storage) best practices page for more
details.

## Resource reservations

Ondat resource consumption depends on the workloads and the Ondat
features in use.

The recommended minimum memory reservation for the Ondat Pods is 512MB for
non-production environments. However it is recommended to prepare nodes so
Ondat can operate with at least with 1-2GB of memory. Ondat frees
memory when possible.

For production environments, we recommend 4GB of Memory and 1 CPU as a minimum
and to test Ondat using realistic workloads and tune resources accordingly.

Ondat Pods resource allocation will impact directly on the availability of
volumes in case of eviction or resource limit triggered restart. It is
recommended to not limit Ondat Pods.

Ondat implements a storage engine, therefore limiting CPU consumption might
affect the I/O throughput of your volumes.

## Maintain a sufficient number of nodes for replicas to be created

To ensure that a new replica can always be created, an additional node should
be available. To guarantee high availability, clusters using Volumes with 1
replica must have at least 3 storage nodes. When using Volumes with 2
replicas, at least 4 storage nodes, 3 replicas, 5 nodes, etc.

Minimum number of storage nodes = 1 (primary) + N (replicas) + 1

For more information, see the section on
[replication](/docs/concepts/replication#number-of-nodes).

## Ondat API username/password

The API grants full access to Ondat functionality, therefore we recommend
that the default administrative password of 'storageos' is reset to something
unique and strong.

You can change the default parameters by encoding the `username` and
`password` values (in base64) into the `storageos-api` secret.

To generate a unique password, a technique such as the following, which
generates a pseudo-random 24 character string, may be used:

```bash
# Generate strong password
PASSWORD=$(cat -e /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()_+~' | fold -w 24 | head -n 1)

# Convert password to base64 representation for embedding in a K8S secret
BASE64PASSWORD=$(echo -n $PASSWORD | base64)
```

Note that the Kubernetes secret containing a strong password *must* be created
before bootstrapping the cluster. Multiple installation procedures use this
Secret to create an Ondat account when the cluster first starts.

## Ondat Pod placement

Ondat must run on all nodes that will contribute storage capacity to the
cluster or that will host Pods which use Ondat volumes. For production
environments, it is recommended to avoid placing Ondat Pods on Master
nodes.

Ondat is deployed with a DaemonSet controller, and therefore tolerates the
standard unschedulable (:NoSchedule) action. If that is the only taint placed
on master or cordoned nodes Ondat pods might start on them (see the
Kubernetes
[docs](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
for more details). To avoid scheduling Ondat pods on master nodes, you can
add an arbitrary taint to them for which the Ondat DaemonSet won't have a
toleration.

## Dedicated instance groups

Cloud environments give users the ability to quickly scale the number of nodes
in a cluster in response to their needs. Because of the ephemeral nature of the
cloud, Ondat recommends setting conservative downscaling policies.

For production clusters, it recommended to use dedicated instance groups for
Stateful applications that allow the user to set different scaling policies and
define Ondat pools based on node selectors to collocate volumes.

Losing a few nodes at the same time could cause the loss of data even when
volume replicas are being used.
