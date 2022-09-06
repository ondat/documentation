---
title: "Ondat Operator"
linkTitle: Ondat Operator
---

Our operator is a [Kubernetes native
application](https://kubernetes.io/docs/concepts/extend-kubernetes/extend-cluster/)
developed to deploy and configure Ondat clusters, and assist with
maintenance operations. We recommend its use for standard installations.

The operator acts as a Kubernetes controller that watches the `StorageOSCluster`
CR (Custom Resource). Once the controller is ready, an Ondat cluster definition can be
created. The operator will deploy an Ondat cluster based on the
configuration specified in the cluster definition.

You can find the source code in the [operator
repository](https://github.com/storageos/operator).
