---
title: "Ondat Data Encryption"
linkTitle: "Ondat Data Encryption"
weight: 1
---

## Overview

> 💡 This feature is available in release `v2.4.0` or greater.

### Data Encryption

Ondat supports [data encryption-at-rest](https://en.wikipedia.org/wiki/Data_at_rest) and [data encryption-in-transit](https://en.wikipedia.org/wiki/Data_in_transit).
- Data encryption-in-transit is data as it is travelling between nodes. It is encrypted by default with [Mutual Authentication (mTLS)](https://en.wikipedia.org/wiki/Mutual_authentication).
- Data encryption-at-rest is the data stored in your volumes as [blob files](/docs/concepts/volumes). Encryption of these blob files is optional and can be enabled by adding a label to your volume definitions **before they are provisioned** .

For more information on how to enable data encryption for Ondat volumes, review the [Ondat Data Encryption](/docs/operations/encryption/) operations page.

### How Are Ondat Volumes Encrypted?

Volumes are encrypted using `AES-256` in the `XTS-AES` mode with `512-bit` keys, as
specified by [`IEEE Standard 1619-2007`](https://standards.ieee.org/ieee/1619/4205/).
- There is a non-zero performance impact of using encrypted volumes. A `10-25%` cost in read/write throughput can be expected from `XTS-AES`, dependent on workload. 
- [Thin provisioning](https://en.wikipedia.org/wiki/Thin_provisioning) still applies to Ondat encrypted volumes.

### How Are Ondat Encryption Keys Generated?

On PVC creation, if data encryption-at-rest is enabled, Ondat will automatically generate **up to two keys** as [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/). Both keys are stored in the **same namespace** as the PVC.
1. Firstly, if it doesn't already exist, a **namespace key** is generated. It is always named `storageos-namespace-key` and **only one exists per namespace**.
1. Secondly a **volume key** is created for each encrypted volume. It has a name in the format `storageos-volume-key-<random-id>`, with no connection to the name of the volume. 
    1. The volume it is associated with can be determined by looking at the `storageos.com/pvc` label on the secret. 
    2. The `storageos.com/encryption-secret-name` and `storageos.com/encryption-secret-namespace` annotations are added to the PVC by an admission controller to map the PVC back to its secret.
1. The encryption key is passed to Ondat as part of the CSI volume creation request and is used to encrypt the volume.

### How Are Encryptions Key Used?

The volume specific secret is needed whenever a volume is attached to a node for use by a pod.
- When this happens, the Ondat node container's [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) reads the secret and passes it to the Ondat Control Plane.
- A volume missing its key or with a malformed key will be unable to attach.
- The key is stored in memory by Ondat only on the node that the volume is being used on. As a result, encryption and decryption are performed **where the data is consumed, rather than where it is stored**.

Because of this, the use of encrypted volumes is transparent to the user. There is a complete integration between Kubernetes applications and Ondat volume encryption.

### Encryption Key Management Best Practices

Ondat saves volume encryption keys in Kubernetes secrets, thus - backups are imperative in case Kubernetes `etcd` backing store is lost or damaged.

> ⚠️ Ondat has no ability to decrypt a volume whose encryption keys have been lost.

Secrets in Kubernetes are not encrypted by default, they are stored in Kubernetes `etcd` backing store in simple [Base64](https://en.wikipedia.org/wiki/Base64) encoding. 
- As Ondat encryption keys are stored as Kubernetes secrets, this means that anyone with access to Kubernetes `etcd` backing store can read encryption keys and decrypt volumes, unless the cluster is using an external secrets store for key management.
- For more information on how to enable and configure encryption of Kubernetes secrets data at rest, review the [official Kubernetes documentation here](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).
- Secrets are not garbage-collected by Ondat, therefore - to clean up completely upon deletion of a volume it is necessary to also delete that volume's secret. There is no benefit to doing this, however.

### Managing Keys With A Key Management Service (KMS) Provider

As mentioned in the section above, Ondat volume encryption keys are stored within Kubernetes `etcd` backing store as Kubernetes secrets. Whilst Kubernetes `etcd` and secrets can also be encrypted, many security-focused organisations choose to use an [external Key Management Service (KMS) provider for data encryption](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/).

To address this from a Kubernetes limitations perspective and provide an agnostic solution, Ondat's encryption design allows the user to leverage any supported [Kubernetes KMS plugin](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/#implementing-a-kms-plugin) to envelop the secrets into a KMS provider encryption scheme.
- Ondat enables end users to transparently integrate any supported KMS plugin with Ondat encryption key management using the standard Kubernetes API and Kubernetes KMS provider framework. The architecture diagram below provides a high level overview of the process.

![KMS Key Management](/images/docs/gui-v2/kms-key-management.png)

1. The KMS plugin is deployed within the Kubernetes cluster.
1. The KMS plugin is configured to act as a broker between the Kubernetes API server and the KMS server API endpoint.
1. At volume creation, Ondat will create a Kubernetes secret using Kubernetes API calls
1. The KMS plugin will handle the Kubernetes API Secret creation call and interface to the KMS server instance.
1. The KMS server will return the secret using its encryption envelop scheme.
1. The KMS plugin will store the encrypted secret within Kubernetes `etcd` backing store.

> 💡 End users can also leverage [Trousseau](https://www.ondat.io/trousseau) with Ondat's volume encryption feature. Trousseau is an open source KMS plugin project that based on Kubernetes KMS provider design. The project allows users to store and access your secrets the Kubernetes native way with any external KMS. Trousseau's repository can be located on [GitHub](https://github.com/ondat/trousseau). 