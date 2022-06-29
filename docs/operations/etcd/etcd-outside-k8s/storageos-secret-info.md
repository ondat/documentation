---
title: "Encryption communication with Etcd"
linkTitle: mTLS
---

Ondat supports secure communication with an external etcd cluster using
mutual TLS (mTLS). With mTLS both Ondat and etcd authenticate each other
ensuring that communication only happens between mutually authenticated end
points, and that all communication is encrypted.

Ondat uses the certificates and keys from a Secret to cypher and
authenticate Etcd traffic.

## How to create the certificates Secret

The client auth certificates need the following filenames, in the Secret.

* etcd-client-ca.crt - containing the etcd Certificate Authority certificate
* etcd-client.crt - containing the etcd Client certificate
* etcd-client.key - containing the etcd Client key

```bash
kubectl create secret -n storageos generic \
    storageos-etcd-secret \
    --from-file="etcd-client-ca.crt" \
    --from-file="etcd-client.crt" \
    --from-file="etcd-client.key"
```

## How to use the mTLS certificates Secret with Ondat

Below is an example StorageOSCluster resource that can be used to setup
Ondat with etcd using mTLS.

```yaml
apiVersion: storageos.com/v1
kind: StorageOSCluster
metadata:
  name: storageos-cluster
spec:
  # Ondat Pods are in storageos NS by default
  secretRefName: "storageos-api"
  storageClassName: "ondat" # The storage class created by the Ondat operator is configurable
  images:
    nodeContainer: "storageos/node:v2.7.0""
  namespace: "storageos"
  # External mTLS secured etcd cluster specific properties
  tlsEtcdSecretRefName: "storageos-etcd-secret"                                   # Secret containing etcd client certificates in the same
  kvBackend:
    address: "https://storageos-etcd-cluster-client.storagos-etcd.svc:2379" # Etcd client service address.
    backend: "etcd"                                                         # Backend type
```

`tlsEtcdSecretRefName` is used to pass a reference to the Secret.

The Ondat operator uses the etcd secret that contains the client
certificates, to build a secret in the Ondat installation namespace. This
secret contains the certificate filenames and certificate file contents. The
Ondat daemonset that is created by the operator mounts the secret as a
volume so that the certificate files are available inside the pod. Environment
variables containing the file paths are passed to the Ondat process in
order to use the files from the mounted path.

A worked example of setting up Ondat with external etcd using mTLS is available
[here](https://github.com/storageos/deploy/tree/master/k8s/deploy-storageos/etcd-helpers/etcd-operator-example-with-tls).
For ease of use the example uses the CoreOS etcd operator and the CoreOS guide
The example uses the CoreOS etcd operator and follows the [CoreOS guide for
Cluster
TLS](https://github.com/coreos/etcd-operator/blob/master/doc/user/cluster_tls.md).
