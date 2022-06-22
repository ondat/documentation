---
title: "Etcd cluster migration"
---

This procedure explains how to migrate data from an etcd cluster running
outside a Kubernetes cluster towards an installation using the Ondat etcd
Operator. As a result the Ondat cluster will use the etcd running as Pods in
Kubernetes.

1. Backup the TLS artifacts from the current etcd cluster (if current etcd uses mTLS)
    The Secret with the TLS material is usually named `storageos-etcd-secret`
    or `etcd-client-tls`

    ```bash
    $ kubectl get secret \
        -n storageos \
        -oyaml \
        etcd-client-tls > etcd-storageos-tls-secret-backup.yaml
    ```

1. Deploy etcd cluster in Kubernetes

    It is required to select a storageClass other than ondat/storageos to run
    etcd in the cluster.

    ```bash
    # Add ondat charts repo.
    $ helm repo add ondat https://ondat.github.io/charts
    # Install the chart in a namespace.
    $ kubectl create namespace etcd-operator
    $ helm install storageos-etcd ondat/etcd-cluster-operator \
        --namespace etcd-operator \
        --set ondat.secret=storageos-etcd-secret-incluster \
        --set cluster.storageclass=standard # Choose the one according to your cluster
    ```

    > ⚠️  The Secret name for the etcd client certificates is amended to avoid
    > using the same Secret name as the one used for the old etcd cluster

    > If the chart is uninstalled the Secret in the storageos namespace with
    > the etcd tls material needs to be deleted manually. A second installation
    > of the chart will not update the secret, thus the certificates won't
    > match.

    > For more details, check the [etcd cluster operator
    > chart](https://github.com/ondat/charts/tree/main/charts/etcd-cluster-operator).

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
      - image: arau/tools:0.9
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
            \$(OLD_ETCD_CMD_OPTS) \
            --dest-cacert \$(NEW_ETCD_CERTS_DIR)/etcd-client-ca.crt \
            --dest-cert \$(NEW_ETCD_CERTS_DIR)/etcd-client.crt \
            --dest-key \$(NEW_ETCD_CERTS_DIR)/etcd-client.key \
            \$(NEW_ETCD_ENDPOINT)
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
    kubectl -n storageos logs etcdctl-migration -f
    ```

    > ⚠️  Wait until the command outputs an integer (the number of keys synced)
    > and leave the command running

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
    Ctrl-C on the shell with the helper pod executing the etcdctl mirror
    command so the mirror stops running

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
    - Delete the helper pod `kubectl -n storageos delete -f helper-etcd-pod.yaml`
    - Decommission the old etcd after a period of safety
