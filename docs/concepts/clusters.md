---
title: "Cluster"
linkTitle: Clusters
---

Ondat clusters represent groups of nodes which run a common distributed
control plane.

Typically, an Ondat cluster maps one-to-one to a Kubernetes (or similar
orchestrator) cluster, and we expect our daemonset to run on all worker
nodes within the cluster that will consume or present storage.

Clusters use etcd to maintain state and manage distributed consensus between
nodes.
