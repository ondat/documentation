---
title: "Etcd"
linkTitle: Etcd
---

[Etcd](https://etcd.io) is an open-source distributed, strongly consistent key value store that is used by Ondat to durably persist the Ondat cluster state. As the backing store for Kubernetes, Ondat uses etcd for many of the same reasons.

Ondat uses etcd as the single source of truth for all Ondat objects.
Whenever a request is made to create, update or delete an object the result is written to etcd before the request is completed. Using etcd as a configuration store allows nodes to retrieve the current cluster state after being offlined, allowing offlined nodes to rejoin the cluster.
