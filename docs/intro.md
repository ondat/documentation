---
sidebar_position: 1
slug: /
---

# Introduction

This documentation is aimed at **architects, engineers, developers, sysadmins** and anybody who wants to understand how to use Ondat. It assumes some knowledge of Docker containers and container orchestrators.

## What is Ondat?
Ondat is a persistent data storage layer for cloud native Kubernetes clusters.


## How does Ondat work with Kubernetes?

### Clusters
Ondat clusters represent groups of nodes which run a common distributed control plane.

Typically, an Ondat cluster maps one-to-one to a Kubernetes (or similar orchestrator) cluster, and we expect our daemonset to run on all worker nodes within the cluster that will consume or present storage.

Clusters use etcd to maintain state and manage distributed consensus between nodes.

### Clusters
Ondat clusters represent groups of nodes which run a common distributed control plane.

Typically, an Ondat cluster maps one-to-one to a Kubernetes (or similar orchestrator) cluster, and we expect our daemonset to run on all worker nodes within the cluster that will consume or present storage.

Clusters use etcd to maintain state and manage distributed consensus between nodes.

### Clusters
Ondat clusters represent groups of nodes which run a common distributed control plane.

Typically, an Ondat cluster maps one-to-one to a Kubernetes (or similar orchestrator) cluster, and we expect our daemonset to run on all worker nodes within the cluster that will consume or present storage.

Clusters use etcd to maintain state and manage distributed consensus between nodes.

