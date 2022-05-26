---
title: "Features"
linkTitle: Features
weight: 200
description: >
    High level overview of Ondat features
---
Ondat offers a wide range of features that would help you to manage your stateful applications on a cluster.

* High Availability - synchronous replication insulates you from node failure through [replication](/docs/features/replication/)

* Delta Sync - replicas out of sync due to transient failures only transfer changed blocks

* [Multiple Access Modes](/docs/features/rwx/) - dynamically provision ReadWriteOnce or ReadWriteMany volumes

* Rapid Failover - quickly detects node failure and automates recovery actions without administrator intervention

* [Data Encryption](/docs/features/encryption/) - both in transit and at rest

* Scalability - disaggregated consensus means no single scheduling point of failure

* Thin provisioning - Only consume the space you need in a storage pool

* Data reduction - transparent inline [data compression](/docs/features/compression/) to reduce the amount of storage used in a backing store as well as reducing the network bandwidth requirements for replication

* Flexible configuration through [labels](/docs/features/labels/) - all features can be enabled per volume, using PVC and StorageClass labels

* Multi-tenancy - fully supports standard Namespace and RBAC methods

* Observability & instrumentation - log streams for observability and Prometheus support for instrumentation

* Deployment flexibility - scale up or scale out storage based on application requirements. Works with any infrastructure – on-premises, VM, bare metal or cloud

* [Fencing](/docs/features/fencing/) -  determine when a node is no longer able to access a volume and has protections in place to ensure that a partitioned or formerly partitioned node can not continue to write data

* [Rolling Upgrades](/docs/features/rolling-upgrades/) of Orchestrators - You can use our rolling upgrade protection feature to upgrade your cluster’s orchestrator without causing downtime or failure of Ondat

* [Snapshots](/docs/features/snapshots) - to enable customers to back up their Ondat data outside of their Kubernetes clusters
