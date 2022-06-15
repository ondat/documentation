---
title: "Ondat Volume Guide"
linkTitle: First PVC
---

Follow the recipes on this page to create your first PVC (Persistent Volume
Claim) using Ondat. Ondat implements dynamic provisioning, so the
creation of a PVC will automatically provision a PV (PersistentVolume) that can
be used to persist data written by a Pod.

## Create the PersistentVolumeClaim

1. You can find the basic examples in the Ondat use-cases repository, in
   the `00-basic` directory.

    ```bash
    git clone https://github.com/storageos/use-cases.git storageos-usecases
    cd storageos-usecases/00-basic
    ```

    PVC definition

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-vol-1
    spec:
      storageClassName: "storageos" # Ondat StorageClass
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ```

    The above PVC will dynamically provision a 5GB volume using the `storageos`
    StorageClass. This StorageClass was created during the Ondat install
    and triggers creation of a PersistentVolume by Ondat.

    For installations with CSI, you can create multiple StorageClasses in order
    to specify default labels.

    ```yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ondat-replicated
    provisioner: csi.storageos.com # Provisioner when using CSI
    parameters:
      csi.storage.k8s.io/fstype: ext4
      storageos.com/replicas: "1" # Enforces 1 replica for the Volume
      csi.storage.k8s.io/secret-name: storageos-api
      csi.storage.k8s.io/secret-namespace: storageos
    ```

    The above StorageClass has the `storageos.com/replicas` label set. This
    label tells Ondat to create a volume with a replica. Adding Ondat
    feature labels to the StorageClass ensures all volumes created with the
    StorageClass have the same labels. For simplicity's sake this example will
    use unreplicated volumes.

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-vol-1
    spec:
      storageClassName: "ondat-replicated" # Reference to the StorageClass
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ```

    You can also choose to add the label in the PVC definition rather than the
    StorageClass. The PVC definition takes precedence over the SC.

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-vol-1
      labels:
          storageos.com/replicas: "1"
    spec:
      storageClassName: "storageos"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ```

    The above PVC has the `storageos.com/replicas` label set. This label tells
    Ondat to add a replica for the volume that is created. For the sake
    of keeping this example simple an unreplicated volume will be used.

1. Move into the examples folder and create a PVC using the PVC definition above.

    ```bash
    # from storageos-usecases/00-basic
    kubectl create -f ./pvc-basic.yaml
     ```

    You can view the PVC that you have created with the command below

    ```bash
    $ kubectl get pvc
    NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    pvc-1        Bound    pvc-f8ffa027-e821-11e8-bc0b-0ac77ccc61fa   5Gi        RWO            storageos       1m
    ```

1. Create a pod that mounts the PVC created in step 2.

    ```bash
    kubectl create -f ./pod.yaml
    ```

    The command above creates a Pod that uses the PVC that was created in step 1.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: d1
    spec:
      containers:
        - name: debian
          image: debian:9-slim
          command: ["/bin/sleep"]
          args: [ "3600" ]
          volumeMounts:
            - mountPath: /mnt
              name: v1
      volumes:
        - name: v1
          persistentVolumeClaim:
            claimName: pvc-1
    ```

    In the Pod definition above volume v1 references the PVC created in step 2,
    and is mounted in the pod at /mnt. In this example a debian image is used
    for the container but any container image with a shell would work for this
    example.

1. Confirm that the pod is up and running

    ```bash
    $ kubectl get pods
    NAME      READY   STATUS    RESTARTS   AGE
    d1        1/1     Running   0          1m
    ```

1. Execute a shell inside the container and write some contents to a file

    ```bash
    $ kubectl exec -it d1 -- bash
    root@d1:/# echo "Hello World!" > /mnt/helloworld
    root@d1:/# cat /mnt/helloworld
    Hello World!
    ```

    By writing to /mnt inside the container, the Ondat volume created by
    the PVC is being written to. If you were to kill the pod and start it again
    on a new node, the helloworld file would still be avaliable.

    **If you wish to see more use cases with actual applications, see our
    [Use Cases](/docs/usecases/) documentation.**
