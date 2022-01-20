---
title: "Encryption"
linkTitle: Encryption
---

For more detail on encryption at rest in Ondat, see [the reference page](/docs/reference/encryption).

## Enabling encryption on a volume

Encrypting a volume is done by simply creating a volume with the
`storageos.com/encryption=true` label. This can be set on the PVC or on
the PVC's StorageClass.

This label is all that is needed. If it is present, the mutating admission
webhook that runs as part of the Ondat API Manager will create the
encryption key, link it to the PVC and store it in a secret.

Encryption is enabled when a volume is provisioned, and it can not be removed
during during the volume's lifetime.

## An example encrypted volume

- Option 1: Label the PVC

    Add the label in the PVC definition, for instance:

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: encrypted-vol
      labels:
        storageos.com/encryption: "true" # Label <-----
    spec:
      storageClassName: "storageos"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1G
    ```

    The encryption label as set on a PVC takes precedence over the encryption
    label as set on the PVC's StorageClass.

- Option 2: Add a parameter to the StorageClass

    Add a parameter to the StorageClass definition. This will cause the above
    label to be present on PVCs created using this StorageClass. For instance:

    ```yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: storageos-encrypted
    provisioner: csi.storageos.com
    allowVolumeExpansion: true
    parameters:
      csi.storage.k8s.io/fstype: ext4
      storageos.com/encryption: "true"
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    ```
