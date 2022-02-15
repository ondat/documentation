---
title: "Cluster Operator examples"
linkTitle: Examples
weight: 30
---

Before deploying an Ondat cluster, create a Secret to define the Ondat
API Username and Password in base64 encoding.

```bash
kubectl create -f - <<END
apiVersion: v1
kind: Secret
metadata:
  name: "storageos-api"
  namespace: "default"
  labels:
    app: "storageos"
type: "kubernetes.io/storageos"
data:
  username: c3RvcmFnZW9z
  password: c3RvcmFnZW9z

END
```

This example contains a default password, for production installations, use a
unique, strong password.

> Make sure that the encoding of the credentials doesn't have special characters such as '\n'.

> You can define a base64 value by `echo -n "mystring" | base64`.


Create a `cluster-config.yaml` according to your needs from the examples below.

```bash
kubectl create -f cluster-config.yaml
```

Note that Ondat will be deployed in `spec.namespace` (storageos by
default), irrespective of what NameSpace the CR is defined in.

&nbsp; <!-- this is a blank line -->

# Examples

> You can checkout all the parameters configurable in the
> [configuration](configuration.md)
> page.

All examples must reference the `storageos-api` Secret.

```yaml
spec:
  secretRefName: "storageos-api" # Reference to the Secret created in the previous step
```

Check out [Cluster Definition
examples](https://github.com/storageos/deploy/tree/master/k8s/deploy-storageos/cluster-operator/examples) for full CR files.

## Installing with an external etcd

```yaml
spec:
  kvBackend:
    address: '10.43.93.95:2379' # IP of the SVC that exposes ETCD
  # address: '10.42.15.23:2379,10.42.12.22:2379,10.42.13.16:2379' # You can specify individual IPs of the etcd servers
```

If using Etcd with mTLS, you need to specify the secret that hold the
certificates with the following parameters:

```yaml
spec:
  # External mTLS secured etcd cluster specific properties
  tlsEtcdSecretRefName: "storageos-etcd-secret" # Secret containing etcd client certificates
  tlsEtcdSecretRefNamespace: "storageos"        # Make sure that the etcd secret is in the same NS as the Ondat cluster
```

Follow the [etcd operations](/docs/operations/etcd/storageos-secret-info) page to setup the
secret with the Etcd client certificate, client key and CA.

## Installing to a subset of nodes

In this case we select nodes that are workers. To make sure that Ondat doesn't start in Master nodes. 

You can see the labels in the nodes by `kubectl get node --show-labels`.

```yaml
spec:
  nodeSelectorTerms:
    - matchExpressions:
      - key: "node-role.kubernetes.io/worker"
        operator: In
        values:
        - "true"

# OpenShift uses "node-role.kubernetes.io/compute=true"
# Rancher uses "node-role.kubernetes.io/worker=true"
# Kops uses "node-role.kubernetes.io/node="
```

> Different provisioners and Kubernetes distributions use node labels
> differently to specify master vs workers. Node Taints are not enough to
> make sure Ondat doesn't start in a node. The
> [JOIN](https://docs.storageos.com/docs/reference/clusterdiscovery)
> variable is defined by the operator by selecting all the nodes that match the
> `nodeSelectorTerms`.

## Enabling CSI

```yaml
spec:
  csi:
    enable: true
    deploymentStrategy: deployment
    enableProvisionCreds: true
    enableControllerPublishCreds: true
    enableNodePublishCreds: true
    enableControllerExpandCreds: true
```

The credentials must be defined in the `storageos-api` Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: "storageos-api"
  labels:
    app: "storageos"
type: "kubernetes.io/storageos"
data:
  # echo -n '<secret>' | base64
  username: c3RvcmFnZW9z
  password: c3RvcmFnZW9z

```

## Specifying a shared directory for use with kubelet as a container

```yaml
spec:
  sharedDir: '/var/lib/kubelet/plugins/kubernetes.io~storageos'
```

## Defining pod resource requests and reservations

```yaml
spec:
  resources:
    requests:
      memory: "512Mi"
  #   cpu: "1"
  # limits:
  #   memory: "4Gi"
```

Limiting Ondat can cause malfunction for IO to Ondat volumes, therefore
we do not currently recommend applying upper limits to resources for Ondat
pods.

## Specifying custom Tolerations

```yaml
spec:
  tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "EffectToTolerate"
  - key: "key2"
    operator: "Exists"
```

Custom tolerations specified in the StorageOSCluster definition are added to
all Ondat components; the Ondat daemonset, CSI helper and scheduler.

In the above example a toleration `key1=value1:EffectToTolerate` would be
tolerated and `key2` would be tolerated regardless of the value and effect. For
more information about tolerations, see the [Kubernetes
documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

