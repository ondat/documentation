---
title: "Automatic data locality"
linkTitle: "Automatic data locality"
---

## Ondat volumes move with their pods

Having an Ondat volume instance on the same node as the pod using it can bring some benifits to your application. Unfortunatly pods can move around over time leaving the Volume behind.

Automatic-Data-Locality fights that, making the master Ondat volume instance follow the pod as it moves between cluster nodes.

⚠️ A new volume instance is created and synced everytime the pod moves, if there's none already on the node where the pod moves to.

## Enablind the feature

This feature is enabled per volume by adding the following label to an Ondat volume:

```yaml
metadata:
  labels:
    storageos.com/automatic-data-locality: "true"
```
