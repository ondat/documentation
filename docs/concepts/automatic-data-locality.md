---
title: "Automatic data locality"
linkTitle: "Automatic data locality"
weight: 1
---

## Ondat volumes move with their pods

When a pod moves to another node, Ondat will make sure the application still has access to the persistent volume, however there may be some additional network hops required if the primary volume is now on a different node to the pod.

This can hurt the performance of the applications, more noticibly when, for example access to a very fast PCIe attached NVMe storage becomes dependent on a network hop impacting both latency and bandwidth.

Automatic-Data-Locality mitigates that, making the primary Ondat volume deployment follow the pod as it moves between cluster nodes.

> Ondat will always place the resilience and protection of your data first, for this reason we only ever remove data when a new deployment has been fully synced within the new node. On account of that, additional space and bandwidth will be required during such an operation.

## Enablind the feature

This feature is enabled per volume by adding the following label to a PVC:

```yaml
metadata:
  labels:
    storageos.com/automatic-data-locality: "true"
```

## Failing to move

Under some scenarios a primary deployment may not be able to follow the pod. For example, if the pod moves to a compute-only node. In such scenario the primary deployment will remain where it currently is.

The change is triggered again when the pod moves again though! And if needed, it can be [moved manually](/docs/concepts/move).
