---
title: "Ondat Feature Labels"
linkTitle: "Ondat Feature Labels"
weight: 1
---

## Overview

Ondat Feature labels are [Kubernetes Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) which provide a powerful and flexible way to control storage features.

- Applying specific feature labels triggers [compression](/docs/concepts/compression/), [replication](/docs/concepts/replication/), [data encryption](/docs/concepts/encryption/) and other storage features. In order to use feature labels, end users are required to explicitly enable the features they want to use in their cluster.

## Types Of Ondat Feature Labels

### Ondat Volume Labels

Below are the list of available feature labels that can be used to define [Volume resources](https://kubernetes.io/docs/concepts/storage/volumes/) and [StorageClass resources](https://kubernetes.io/docs/concepts/storage/storage-classes/#the-storageclass-resource) in an Ondat cluster.

> 💡 The **encryption** and **compression** labels can only applied at provisioning time, they can't be changed during execution.

| Feature Name                                                        | Label Reference                | Values                                                                                         | Feature Description                                                                                                                                                                                                                            |
| :------------------------------------------------------------------ | :----------------------------- | :--------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**Compression**](/docs/concepts/compression/)                      | `storageos.com/nocompress`     | `true` / `false`                                                                               | Enables or disables compression of data-at-rest and data-in-transit. Compression **is not enabled by default** to maximise performance.                                                                                                        |
| [**Encryption**](/docs/concepts/encryption/)                        | `storageos.com/encryption`     | `true` / `false`                                                                               | Encrypts the contents of the volume. For each volume, a key is automatically generated, stored, and linked with the PVC.                                                                                                                       |
| [**Failure Mode**](/docs/concepts/replication/#ondat-failure-modes) | `storageos.com/failure-mode`   | `hard`, `soft`, `alwayson`, or `threshold` integers starting from `0` to `5`                   | Sets the failure mode for a volume, either explicitly using a failure mode or implicitly using a replica threshold. The default setting of a failure mode is `hard`.                                                                           |
| [**Replication**](/docs/concepts/replication/)                      | `storageos.com/replicas`       | `integers` starting from `0` to `5`                                                            | Sets the number of replicas, for example full copies of the data across nodes. Typically `1` or `2` replicas is sufficient (`2` or `3` instances of the data). Latency implications need to be assessed when using **more than** `2` replicas. |
| [**Topology-Aware Placement**](/docs/concepts/tap/)                 | `storageos.com/topology-aware` | `true` / `false`                                                                               | Enables or disables Ondat Topology-Aware Placement.                                                                                                                                                                                            |
| [**Topology Domain Key**](/docs/concepts/tap/#topology-domains)     | `storageos.com/topology-key`   | custom region, read as a [string](https://en.wikipedia.org/wiki/String_%28computer_science%29) | Define the failure domain for the node by using a custom key. If you don't define a custom key, the label defaults to the `topology.kubernetes.io/zone` value.                                                                                 |

### Ondat Node Labels

When Ondat is run within Kubernetes, the [Ondat API Manager](https://github.com/storageos/api-manager) syncs any [Kubernetes node labels](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/) to the corresponding Ondat node. The Kubernetes node labels act as the "source of truth", so labels should be applied to the Kubernetes nodes rather than to Ondat nodes. This is because the Kubernetes node labels overwrite the Ondat node labels on sync.

- Below are the list of available feature labels that can be used to define [Kubernetes Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/) in an Ondat Cluster.

| Feature Name                                                      | Label Reference             | Values           | Feature Description                                                                                                                                                                                                                     |
| :---------------------------------------------------------------- | :-------------------------- | :--------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**Compute-only Nodes**](/docs/concepts/nodes/#compute-only-mode) | `storageos.com/computeonly` | `true` / `false` | Specifies whether a node should be `computeonly` where it only acts as a client and does not host volume data locally, otherwise the node is hyper-converged (the default), where the node can operate in both client and server modes. |

### Ondat Pod Labels

Below are the list of available feature labels that can be used to define [Kubernetes Pods](https://kubernetes.io/docs/concepts/workloads/pods/) in an Ondat Cluster.

> 💡 For a pod to be fenced by Ondat, a recommendation will be to review the the [Ondat Fencing](/docs/operations/fencing) operations page for more information.

| Feature Name                               | Label Reference        | Values           | Feature Description                                                              |
| :----------------------------------------- | :--------------------- | :--------------- | :------------------------------------------------------------------------------- |
| [**Pod Fencing**](/docs/concepts/fencing/) | `storageos.com/fenced` | `true` / `false` | Targets a pod to be fenced in case of node failure. The default value is `false` |

## How To Use Ondat Feature Labels?

For more information about how to enable specific Ondat features, review the Ondat Feature Labels operations pages listed below;

- [How To Setup A Centralised Cluster Topology](/docs/operations/compute-only).
- [How To Use Volume Replication](/docs/operations/replication).
- [How To Use Failure Modes](/docs/operations/failure-modes/).
- [How To Enable Fencing](/docs/operations/fencing/).
- [How To Enable Topology-Aware Placement (TAP)](/docs/operations/tap/).
- [How To Enable Data Encryption](/docs/operations/encryption/).
- [How To Enable Data Compression](/docs/operations/compression).
