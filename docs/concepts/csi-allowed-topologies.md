---
title: "CSI Allowed Topologies"
linkTitle: "CSI Allowed Topologies"
weight: 1
---
## Overview

> 💡 This feature is available in release `v2.9.0` or greater.

Ondat allows use of CSI's Allowed Topology feature, for ensuring volumes
are located in specified lists of topologies, where 'topology' is taken to
mean a description of a node's location, some sub-division of a cluster.

In Kubernetes topologies are defined by node labels. As it stands, the only
label Ondat supports for this purpose is `topology.kubernetes.io/zone`, the
Kubernetes' default label for representing "a logical failure domain".

### When to use CSI Allowed Topologies

CSI Allowed Topologies allows you to configure the "topologies" that a volume
is allowed to be placed in, ensuring localised access for given workloads and
availibility zones.

As such, an example use case would be for a workload that has an affinity
for a given region of a cluster, ensuring that a deployment of that workload's
volume is always available in that same region for lowered latency and
fault-tolerance.

### Detailed CSI Allowed Topologies Behaviour

Where T is the set of allowed topologies, D is the set of volume deployments
(primary & replicas) and |T| and |D| are the sizes of those respective sets,
Ondat's provisioning behaviour is this:
- When |T|>|D| - All deployments are created on nodes within |D| unique topologies within T.
- When |T|=|D| - All topologies in T contain exactly one deployment.
- When |T|<|D| - All topologies in T contain at least one deployment.

So all allowed topologies will be populated with deployments if able, and if
there are more deployments than allowed topologies those deployments can be
placed on other toplogies.

## How to use

You can enable by applying a `storageos.com/fixed-topology: "true"` label to
any PVC that uses a StorageClass with an `allowedTopologies` block.

- For more information on how to enable CSI Allowed Topologies for your
volumes, review the [Ondat CSI Allowed Topologies](/docs/operations/csi-allowed-topologies)
operations page.

## Useful links

 - The CSI spec's definition of the Topology Requirement feature: https://github.com/container-storage-interface/spec/blob/master/spec.md#controller-service-rpc
 - Docs on Kubernetes' CSI's implementation of the CSI Topology Requirement feature: https://kubernetes-csi.github.io/docs/topology.html#sidecar-deployment
   - Please note that there are discrepencies between this implementation and the original spec. In these cases the Kubernetes implementation should be seen to supersede.
 - The description of the `topology.kubernetes.io/zone` label, with information on how it's set by cloud providers: https://kubernetes.io/docs/reference/labels-annotations-taints/#topologykubernetesiozone
