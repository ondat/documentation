---
title: "Etcd cluster migration"
---


This procedure explains how to migrate data from an etcd cluster running
outside a Kubernetes cluster towards an installation using the Ondat etcd
Operator. As a result the Ondat cluster will use the etcd running as Pods in
Kubernetes.

## Prerequisites

- Kubectl
- Helm

It is assumed that both etcd clusters in this procedure are using mTLS.

## Procedure

### Option A - Manual process

1. Backup the TLS artifacts from the current etcd cluster (if current etcd uses mTLS)
    The Secret with the TLS material is usually named `storageos-etcd-secret`
    or `etcd-client-tls`

    ```bash
    $ kubectl get secret \
        -n storageos \
        -o yaml \
        etcd-client-tls > etcd-storageos-tls-secret-backup.yaml
    ```

1. Deploy etcd cluster in Kubernetes

    ⚠️  It is required to select a storageClass other than ondat/storageos to
    run etcd in the cluster. If there is none available in the cluster, you can
    run the following to deploy a [Local Path
    Provisioner](https://github.com/rancher/local-path-provisioner) to provide
    local storage for Ondat's embedded `etcd` cluster operator deployment. Even
    though, that CSI provisioner is not intended for production.

    __(Optional) Deploy Local path storageClass__

    ```bash
    kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
    ```

    __Deploy etcd__

    ```bash
    # Add ondat charts repo.
    $ helm repo add ondat https://ondat.github.io/charts
    # Install the chart in a namespace.
    $ helm install storageos-etcd ondat/etcd-cluster-operator \
        --namespace etcd-operator \
        --create-namespace \
        --set ondat.secret=storageos-etcd-secret-incluster \
        --set cluster.storageclass=standard # Choose the one according to your cluster
    ```

    > ⚠️  The Secret name for the etcd client certificates is amended to avoid
    > using the same Secret name as the one used for the old etcd cluster

    > For more details, check the [etcd cluster operator
    > chart](https://github.com/ondat/charts/tree/main/charts/component-charts/etcd-cluster-operator).

1. Validate etcd

    Check that etcd pods are starting

    ```bash
    $ kubectl -n storageos-etcd get pod
    NAME                     READY   STATUS    RESTARTS   AGE
    storageos-etcd-0-7b755   1/1     Running   0          1m
    storageos-etcd-1-q6k5q   1/1     Running   0          1m
    storageos-etcd-2-s6kck   1/1     Running   0          1m
    ```

    > The pods might take a few minutes to be ready

1. Copy and amend the helper pod definition
    The following pod will be used as a bridge between the old etcd and the new
    one. Because of that, it is required to amend the env vars pointing to the
    URLs of the clusters and mount the TLS secrets to access both of them

    Create a file `helper-etcd-pod.yaml` with the following contents.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        run: etcdctl
      name: etcdctl-migration
    spec:
      containers:
      - image: quay.io/coreos/etcd:v3.5.3
        name: etcdctl
        env:
        - name: OLD_ETCD_ENDPOINT
          value: https://ip-192-168-17-118.eu-west-1.compute.internal:2379
        - name: NEW_ETCD_ENDPOINT
          value: https://storageos-etcd.storageos-etcd:2379
        - name: OLD_ETCD_CERTS_DIR
          value: '/etc/etcd_old/certs' # defined in the volumes from a Secret
        - name: NEW_ETCD_CERTS_DIR
          value: '/etc/etcd_new/certs' # defined in the volumes from a Secret
        - name: OLD_ETCD_CMD_OPTS
          value: "--endpoints $(OLD_ETCD_ENDPOINT) --cacert $(OLD_ETCD_CERTS_DIR)/etcd-client-ca.crt --key $(OLD_ETCD_CERTS_DIR)/etcd-client.key --cert $(OLD_ETCD_CERTS_DIR)/etcd-client.crt"
        - name: NEW_ETCD_CMD_OPTS
          value: "--endpoints $(NEW_ETCD_ENDPOINT) --cacert $(NEW_ETCD_CERTS_DIR)/etcd-client-ca.crt --key $(NEW_ETCD_CERTS_DIR)/etcd-client.key --cert $(NEW_ETCD_CERTS_DIR)/etcd-client.crt"
        command: [ "/bin/sh", "-c" ]
        args:
        - "
            etcdctl make-mirror \
            $(OLD_ETCD_CMD_OPTS) \
            --dest-cacert $(NEW_ETCD_CERTS_DIR)/etcd-client-ca.crt \
            --dest-cert $(NEW_ETCD_CERTS_DIR)/etcd-client.crt \
            --dest-key $(NEW_ETCD_CERTS_DIR)/etcd-client.key \
            $(NEW_ETCD_ENDPOINT)
        "
        volumeMounts:
        - mountPath: /etc/etcd_old/certs
          name: cert-dir-old
        - mountPath: /etc/etcd_new/certs
          name: cert-dir-new
      volumes:
      - name: cert-dir-old
        secret:
          defaultMode: 420
          secretName: storageos-etcd-secret
      - name: cert-dir-new
        secret:
          defaultMode: 420
          secretName: storageos-etcd-secret-incluster
    ```

    - Amend the env var `OLD_ETCD_ENDPOINT` with your cluster's URL
    - Amend the `spec.volumes.secret.secretName` according to the Secrets'
      names on your cluster.

1. Run the helper pod

    ```bash
    kubectl -n storageos create -f ./helper-etcd-pod.yaml
    ```

    > The helper pod creates a mirror between both etcd clusters

1. Wait for the mirror

    ```bash
    $ kubectl -n storageos logs etcdctl-migration -f
    893
    ```

    > ⚠️  Wait until the command outputs an integer (the number of keys synced).
    > The number must not be 0. If that is the case:
    >
    > 1. Exec to the pod:
        ```
        kubectl -n storageos exec -it etcdctl-migration -- bash
        ```
    > 2. Check env vars
        ```
        env | grep ETCD
        ```
    > 3. Check connectivity
        ```
        etcdctl $OLD_ETCD_CMD_OPTS member list;
        etcdctl $NEW_ETCD_CMD_OPTS member list
        ```

1. Stop stateful applications
    Scale down to 0 replicas all applications using Ondat volumes and wait
    until all pods are stopped

    i.e

    ```bash
    kubectl scale statefulset YOUR_STS --replicas=0
    ```

1. Backup StorageOS CustomResource

    ```bash
    kubectl get storageosclusters.storageos.com \
        -n storageos  \
        -oyaml \
        storageoscluster > storageos-cluster.yaml
    ```

    Verify the backup

    ```bash
    cat storageos-cluster.yaml
    ```

1. Stop Ondat

    ```bash
    kubectl -n storageos delete storageosclusters.storageos.com storageoscluster
    ```

1. Stop mirror

    ```bash
    kubectl -n $STOS_NS delete pod etcdctl-migration
    ```

1. Amend the StoragseOS Cluster CustomResource

    Edit the file `storageos-cluster.yaml`

    - Set the new etcd address in `kvBackend.address`
    - Set the new Secret in `tlsEtcdSecretRefName`

    i.e:

    ```yaml
    spec:
      ...
      kvBackend:
        address: storageos-etcd.storageos-etcd:2379
      tlsEtcdSecretRefName: storageos-etcd-secret-incluster
      tlsEtcdSecretRefNamespace: storageos
    ```

1. Start Ondat

    ```bash
    $ kubectl -n storageos create -f storageos-cluster.yaml

    storageoscluster.storageos.com/storageoscluster created
    ```

    Wait until pods are running

    ```bash
    $ kubectl -n storageos get pod
    NAME                                   READY   STATUS    RESTARTS      AGE
    etcdctl-migration                      1/1     Running   0             8m5s
    storageos-operator-67678c896d-npq5m    2/2     Running   6 (33m ago)   5h44m
    storageos-scheduler-7fdb74fb8c-t675h   1/1     Running   0             2s
    storageos-node-8z7mj                   3/3     Running           0             2s
    storageos-node-r8trk                   3/3     Running           0             2s
    storageos-node-c28pk                   3/3     Running           0             3s
    storageos-api-manager-5cccf759d8-c58tx   1/1     Running             0             1s
    storageos-csi-helper-65db657d7c-hqvdt    3/3     Running             0             2s
    storageos-api-manager-5cccf759d8-ppxhd   1/1     Running             0             2s
    ```

1. Validate Ondat is connecting to the new etcd
    Search for `ETCD connection established` and the new etcd URL in the logs
    of the daemonset pods.

   The pattern suggested must be found on any of the daemonset `node` pods.

   ```bash
   $ kubectl -n storageos logs ds/storageos-node | grep "ETCD connection established"
   {"level":"info","msg":"ETCD connection established at: [storageos-etcd.storageos-etcd:2379]","time":"2022-06-20T16:16:05.593281009Z"}
   ```

1. Start stateful applications

1. Clean up
   - Decommission the old etcd after a period of safety.
   - Delete old TLS secret from the StorageOS namespace when the etcd is decommissioned.

### Option B - Automated

> Before starting this procedure it is required to stop all usage of Ondat
> volumes. Therefore any stateful applications need to be scaled to 0.

> ⚠️  It is required to select a storageClass other than ondat/storageos to run
> etcd in the cluster. If there is none available in the cluster, you can run
> the following to deploy a [Local Path
> Provisioner](https://github.com/rancher/local-path-provisioner) to provide
> local storage for Ondat's embedded `etcd` cluster operator deployment. Even
> though, that CSI provisioner is not intended for production.

__(Optional) Deploy Local path storageClass__

```bash
kubectl apply --filename="https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.21/deploy/local-path-storage.yaml"
```

The following script executes the same steps as the manual procedure.

1. Download script

    ```bash
    curl -s https://raw.githubusercontent.com/ondat/use-cases/main/scripts/migrate-etcd-external-to-pods.sh -o migrate-etcd-external-to-pods.sh \
        && chmod +x migrate-etcd-external-to-pods.sh
    ```

1. Run the migration

    ```bash
    ETCD_STORAGECLASS=YOUR_STORAGE_CLASS # fill this env var
    ETCD_ENDPOINT=PROD_ETCD_ENDPOINT # fill this env var
    ./migrate-etcd-external-to-pods.sh -s $ETCD_STORAGECLASS -e $ETCD_ENDPOINT
    ```

    For example:

    ```bash
    $ ETCD_STORAGECLASS=local-path
    $ ETCD_ENDPOINT="ip-192-168-17-118.eu-west-1.compute.internal:2379"
    $ ./migrate-etcd-external-to-pods.sh \
        -s $ETCD_STORAGECLASS \
        -e $ETCD_ENDPOINT

     Storing a backup of the storageos-etcd-secret in /tmp/etcd-client-tls.yaml
     Release "storageos-etcd" does not exist. Installing it now.
     NAME: storageos-etcd
     LAST DEPLOYED: Wed Jun 22 16:44:43 2022
     NAMESPACE: etcd-operator
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None
     Wating for etcd to be ready
     ...........................
     Etcd is ready
     pod/etcdctl-migration created
     Wating for the mirror
     ......................
     Mirror between etcds is running successfully
     Backing up the StorageOSCluster configuration
     Stopping Ondat
     storageoscluster.storageos.com "storageoscluster" deleted
     Stopping etcd mirror
     pod "etcdctl-migration" deleted
     Starting Ondat
     storageoscluster.storageos.com/storageoscluster created
     Wating for Ondat to be ready
     ...........
     Ondat is ready
     Checking that Ondat is pointing to the new etcd cluster in the node container logs:
       success!
    ```
