---
title: "Namespaces"
linkTitle: Namespaces
---

Ondat namespaces are an identical concept to Kubernetes namespaces. They
are intended to allow an Ondat cluster to be used by multiple teams across
multiple projects.

It is not necessary to create Ondat namespaces manually, as Ondat maps
Kubernetes namespaces on a one-to-one basis when PersistentVolumeClaims using
the Ondat StorageClass are created.

Access to Namespaces is controlled through user or group level [policies](/docs/concepts/policies).
