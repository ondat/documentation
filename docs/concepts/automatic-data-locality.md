---
title: "Automatic data locality"
linkTitle: "Automatic data locality"
weight: 1
---

## Ondat volumes move with their pods

Having an Ondat volume deployment on the same node as the pod using it can improve the performance of your application. Unfortunately pods can move around over time leaving the volume behind.

Automatic-Data-Locality mitigates that, making the primary Ondat volume deployment follow the pod as it moves between cluster nodes.

⚠️ A new volume deployment may need to be created and synced everytime the pod moves, which can lead to a significant increase in network traffic on the cluster.

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

## Safety first

The process is safe to use and only ever removes data when a new deployment of it has been synced within the new node.
