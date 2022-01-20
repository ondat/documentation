---
title: "Encryption"
linkTitle: Encryption
---

Ondat supports encryption for data-at-rest and data-in-transit.

Data-in-transit is data as it is travelling between nodes. It is encrypted by
default with mTLS. Data-at-rest is the data stored in your volumes as [blob files](/docs/concepts/volumes). Encryption of these blob files
is optional and can be enabled by adding a label to your volume definitions
before they're provisioned.

For information on how to enable encryption on your volumes, please see our
[Encryption Operations](/docs/operations/encryption) page.

## How volumes are encrypted

Volumes are encrypted using AES-256 in the XTS-AES mode with 512-bit keys, as
specified by IEEE Standard 1619-2007. There is a non-zero performance impact of
using encrypted volumes. A 10-25% cost in read/write throughput can be
expected from XTS-AES, dependent on workload. Thin provisioning still applies
to encrypted volumes.

## Encryption Key Generation

On PVC creation, [if encryption is enabled](/docs/reference/labels#storageos-volume-labels), Ondat will
automatically generate up to two keys as Kubernetes secrets. Both keys are
stored in the same namespace as the PVC.

Firstly, if it doesn't already exist, a namespace key is generated. It is
always named `storageos-namespace-key` and only one exists per namespace.

Secondly a volume key is created for each encrypted volume. It has a name in
the format `storageos-volume-key-<random-id>`, with no connection to the name
of the volume. The volume it is associated with can be determined by looking at
the `storageos.com/pvc` label on the secret. The
`storageos.com/encryption-secret-name` and
`storageos.com/encryption-secret-namespace` annotations are added to the PVC by
an admission controller to map the PVC back to its secret.

The encryption key is passed to Ondat as part of the CSI volume creation
request and is used to encrypt the volume.

## Encryption Key Use

The volume specific secret is needed whenever a volume is attached to a node
for use by a pod. When this happens, the Ondat node container's Service
Account reads the secret and passes it to the Ondat controlplane.

A volume missing its key or with a malformed key will be unable to attach.

The key is stored in memory by Ondat only on the node that the volume is
being used on. As a result, encryption and decryption are performed where the
data is consumed, rather than where it is stored.

Because of this, the use of encrypted volumes is transparent to the user.
There is a complete integration between Kubernetes applications and
Ondat encryption.

## Key Management Best Practices

Ondat saves encryption keys in Kubernetes Secrets.
Backups are therefore imperative in case the Kubernetes Etcd is lost.
**Ondat has no ability to decrypt a volume whose encryption keys have been
lost.**

Secrets in Kubernetes are not encrypted by default, they are stored in the
Kubernetes Etcd in simple Base64 encoding. As Ondat encryption keys are
stored as Kubernetes Secrets, this means that anyone with access to a
Kubernetes Etcd installation can read encryption keys and decrypt volumes,
unless the cluster has an external secrets store.

For better security check Kubernetes [secret
encryption](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).

Secrets are not garbage-collected by Ondat. To clean up completely upon
deletion of a volume it is necessary to also delete that volume's secret. There
is no benefit to doing this, however.

## Key Management with Kubernetes KMS provider

Ondat encryption keys are stored within Etcd as Kubernetes secrets. Whilst
the Etcd and kubernetes secrets [can also be
encrypted](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/),
many organisations choose to use an external KMS provider.

To address this from a Kubernetes limitations perspective and provide an
agnostic solution, our encryption design allows the user to benefit from any
Kubernetes KMS provider plugin to envelop the secrets into the KMS provider
encryption scheme.

Ondat allows customers to transparently integrate any supported KMS plugin
with Ondat encryption key management using the standard Kubernetes API and
Kubernetes KMS provider framework. The below figure provides an overview of the
process.

![KMS Key Management](/images/docs/gui-v2/kms-key-management.png)

1. The KMS plugin is deployed within the Kubernetes cluster.
2. The KMS plugin is configured to act as a broker between the Kubernetes API
   server and the KMS server API endpoint.
3. At volume creation, Ondat will create a Kubernetes secret using
   Kubernetes API calls
4. The KMS plugin will handle the Kubernetes API Secret creation call and
   interface to the KMS server instance.
5. The KMS server will return the secret using its encryption envelop scheme.
6. The KMS plugin will store the encrypted secret within the Kubernetes Etcd.

Contact the [Ondat sales team](mailto:sales@storageos.com) for more
information about the dedicated Ondat Vault KMS plugin integration
offering.
