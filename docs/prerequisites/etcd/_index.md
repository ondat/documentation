---
title: "Etcd"
---

Ondat requires an etcd cluster in order to function. For more information on
why etcd is required, see our [etcd concepts](/docs/concepts/etcd) page.

The Kubernetes etcd cannot be used for Ondat's configuration as per Kubernetes
requirements.

For most use-cases it is recommended installing the Ondat etcd operator, which
will manage creation and maintenance of Ondat's required etcd cluster. In some
circumstances it makes sense to install etcd on separate machines outside of
your Kubernetes cluster.
