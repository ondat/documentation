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

## How mTLS Works with the Etcd Operator

When mTLS is enabled, the etcd operator will handle the creation of mTLS certificates, as well as the Kubernetes secrets Ondat requires.

## How to enable mTLS

Enabling mTLS must be done at etcd cluster creation time. It is not possible to retroactively enable mTLS.

The method to enable mTLS depends on how you are installing the etcd operator, guides are [available here](/docs/prerequisites/etcd).

In short:

* Helm chart: mTLS is enabled by default
* Plugin: mTLS is enabled when using the `--etcd-tls-enabled` flag
* Applying CR directly: Set the following in the CR

```
spec:
  tls:
    enabled: true
    storageOSClusterNamespace: "storageos"
    storageOSEtcdSecretName: "storageos-etcd-secret"
```
