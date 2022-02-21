---
linkTitle: "Rolling Upgrades to Orchestrator"
---

# Upgrade Guard

You can use the rolling upgrade feature to upgrade an orchestrator (for example, Kubernetes or OpenShift) without causing service downtime/cluster failure. For example, OpenShift provides a one-click upgrade but that feature doesn't take into consideration Stateful workloads. By doing rolling upgrades without waiting for the replicas to sync you can cause major issues on the affected volumes.

We have developed a separate component called the upgrade guard. This component blocks certain nodes from being upgraded or drained thus avoiding data loss in the cluster.
To use the rolling upgrade feature, you need to enable both the Node manager and the Upgrade Guard components (this is set on the `storageoscluster` CR).

The upgrade guard will detect if a volume is unhealthy (for example, one that doesn't have enough synced replicas), at which point one or more node manager pods will become unavailable. Ondat uses the PodDisruptionBudget (PDB) to stop more than 1 node manager pod being unavailable at any point in time.

If the PDB is set to 1 and a Control Plane volume on a node is not ready for a long period of time, this will stop the upgrade process. The `api-managercomponent` will be able to dynamically set the PDB value if it can determine the health of the volume. If the `api-managercomponent` knows that a volume will not be ready, it can increase the PDB `maxUnavailable` value, allowing the upgrade to continue.

>note: There is some latency between a volume becoming unhealthy and the Upgrade guard noticing (due to the polling nature of both the `api-managercomponent` volume sync Kubernetes readiness endpoints).
The upgrade guard container is only monitoring volumes that host a deployment on its node (fro example, it doesn’t care if a volume is unhealthy if the node it's running on hosts none of the volumes master and replicas)
The upgrade guard container will log when it’s available to upgrade, it will also log the reason if upgrade is not possible.

# Node Manager

The Node manager is an out-of-band pod used for node management.  It runs on all nodes that run the `StorageOS` node container and is a separate pod so that it can be restarted independently of the node container. Upgrade guard solves the main issue of the node manager: deploys a pod next to all `StorageOS` daemonset and monitors local node state.
