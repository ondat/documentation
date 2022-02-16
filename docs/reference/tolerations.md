---
title: "Tolerations"
linkTitle: Tolerations
---

## Kubernetes Tolerations

Tolerations are a Kubernetes pod property that allow pods to tolerate certain
node taints. Taints can be thought of as the opposite of Node affinity in that
taints repel pods. Node taints are automatically applied by Kubernetes in
response to node resources coming under contention. As Ondat provides
storage to pods it should not be evicted during periods of resource contention,
as any pods using Ondat volumes on the same node would need to be
restarted.

As Ondat runs as a daemonset some Kubernetes tolerations are added by
Kubernetes while others are automatically added by the Ondat operator.

For more information about tolerations, see the [Kubernetes
documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

```yaml
tolerations:
# The unreachable and not-ready tolerations are added by Kubernetes to daemonsets automatically
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
- key: "node.kubernetes.io/not-ready"
  operator: "Exists"
  effect: "NoExecute"

# The following tolerations are added to the Ondat daemonset by the Ondat operator
- key: node.kubernetes.io/disk-pressure
  operator: Exists
- key: node.kubernetes.io/memory-pressure
  operator: Exists
- key: node.kubernetes.io/network-unavailable
  operator: Exists
- key: node.kubernetes.io/out-of-disk
  operator: Exists
- key: node.kubernetes.io/pid-pressure
  operator: Exists
- key: node.kubernetes.io/unschedulable
  operator: Exists

```

## Adding Custom Tolerations

To add custom tolerations to the Ondat daemonset [configure them in the
StorageOSCluster
resource](/docs/reference/cluster-operator/examples#specifying-custom-tolerations).
