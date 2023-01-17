---
title: "Automatic data locality"
linkTitle: "Automatic data locality"
weight: 1
---

## Ondat volumes move with their pods

Having an Ondat volume instance on the same node as the pod using it can bring some benifits to your application. Unfortunatly pods can move around over time leaving the Volume behind.

Automatic-Data-Locality mitigates that, making the primary Ondat volume instance follow the pod as it moves between cluster nodes.

⚠️ A new volume instance may need to be created and synced everytime the pod moves, which can lead to a significant increase in network traffic on the cluster.

## Enablind the feature

This feature is enabled per volume by adding the following label to a PVC:

```yaml
metadata:
  labels:
    storageos.com/automatic-data-locality: "true"
```

## Failing to move

Under some specific scenarios a volume instance may not be able to follow a pod, I.E. into a compute-only node, thus remains where it current is.

The change is triggered again when the pod moves again though! And if needed, it can be [moved manually](/docs/concepts/move.md).

## Safety first

The process is safe to use and only ever removes data when a new instance of it has been synced within the new node.