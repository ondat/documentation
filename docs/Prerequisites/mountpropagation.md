---
title: "Mount Propagation"
linkTitle: Mount Propagation
weight: 300
---

> 💡 Modern versions of Kubernetes or other Container Runtimes enable
> mount propagation by default.

Ondat requires mount propagation enabled to present devices as volumes for
containers (see linux kernel documentation
[here](http://man7.org/linux/man-pages/man2/mount.2.html)).

Orchestrators such as Kubernetes or OpenShift have their own ways of exposing
this setting. Kubernetes 1.10 and OpenShift 3.10 have mount propagation enabled by
default. Previous versions require that feature gates are enabled on the
Kubernetes master's `controller-manager` and `apiserver` services and in the
`kubelet` service on each node.

Refer to our installation pages for the orchestrators to see details on how to
check and enable mount propagation where appropriate.
