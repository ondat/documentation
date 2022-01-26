---
title: "Etcd"
linkTitle: Etcd
weight: 600
---

Ondat requires an etcd cluster in order to function. For more information
on why etcd is required please see our [etcd concepts](/docs/concepts/etcd) page.

We do not support using the Kubernetes etcd for Ondat installations.

We provide two methods for installing etcd. For those looking for a quick
route to evaluating Ondat, our first method installs etcd into your
Kubernetes cluster using the CoreOS operator. Due to limitations in the CoreOS
operator, this installation is not backed by any persistent storage, and
therefore is unsuitable for production installations.

For production installations, there is currently no satisfactory way of
installing a production-grade etcd cluster inside Kubernetes (although the
landscape is changing rapidly, watch this space), and our production guidance
remains to install etcd on separate machines outside of your Kubernetes
cluster. This method is the best way to ensure a stable Ondat cluster.
Please see our etcd operations page for additional information on deployment
[best practices](/docs/operations/etcd/_index) and concerns.

1. Ephemeral pods within Kubernetes (*Testing*)
1. External Virtual Machines (*Production*)

Click the tabs below to select the installation method of your choice.

## Testing - Installing Etcd Into Your Kubernetes Cluster

__This fast and convenient method is useful for quickly creating an etcd
cluster in order to evaluate Ondat. Do not use it for production
installations.__

This method uses the [CoreOS
etcd-operator](https://github.com/coreos/etcd-operator) to install a 3 node
etcd cluster within your Kubernetes cluster, in the `storageos-etcd`
namespace. We then install a Kubernetes service in that same namespace.

The official etcd-operator repository also has a backup deployment operator
that can help backup etcd data. __A restore of the etcd keyspace from a backup
might cause issues__ due to the disparity between the cluster state and its
metadata in a different point in time. If you need to restore from a backup
after a failure of etcd, contact the Ondat support team.

### Quick Install

For a one command install, the following script uses `kubectl` to create an
etcd cluster in the `storageos-etcd` namespace. It requires kubectl in the
system path, and the context set to the appropriate cluster.

```bash
curl -s https://raw.githubusercontent.com/ondat/use-cases/main/scripts/deploy-etcd.sh | bash
```

### Installation Step by Step

For those who would prefer to execute the steps by themselves, they are as
follows:

1. Configure Namespace

    ```bash
    export NAMESPACE=storageos-etcd
    ```

1. Create Namespace

    ```bash
    kubectl create namespace $NAMESPACE
    ```

1. If running in Openshift, an SCC is needed to start Pods

    ```bash
    oc adm policy add-scc-to-user anyuid system:serviceaccount:$NAMESPACE:default
    ```

1. Create ClusterRole and ClusterRoleBinding

    ```bash
     $ kubectl -n $NAMESPACE create -f-<<END
     apiVersion: rbac.authorization.k8s.io/v1beta1
     kind: ClusterRoleBinding
     metadata:
       name: etcd-operator
     roleRef:
       apiGroup: rbac.authorization.k8s.io
       kind: ClusterRole
       name: etcd-operator
     subjects:
       - kind: ServiceAccount
         name: default
         namespace: $NAMESPACE
    END
    ```

    ```bash
    $ kubectl -n $NAMESPACE create -f-<<END
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRole
    metadata:
      name: etcd-operator
    rules:
    - apiGroups:
      - etcd.database.coreos.com
      resources:
      - etcdclusters
      - etcdbackups
      - etcdrestores
      verbs:
      - "*"
    - apiGroups:
      - apiextensions.k8s.io
      resources:
       - customresourcedefinitions
      verbs:
      - "*"
    - apiGroups:
      - ""
      resources:
      - pods
      - services
      - endpoints
      - persistentvolumeclaims
      - events
      verbs:
      - "*"
    - apiGroups:
      - apps
      resources:
      - deployments
      verbs:
      - "*"
    # The following permissions can be removed if not using S3 backup and TLS
    - apiGroups:
      - ""
      resources:
      - secrets
      verbs:
      - get
    END
    ```

1. Deploy Etcd Operator

    ```bash
    $ kubectl -n $NAMESPACE create -f - <<END
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: etcd-operator
    spec:
      selector:
        matchLabels:
          app: etcd-operator
      replicas: 1
      template:
        metadata:
          labels:
            app: etcd-operator
        spec:
          containers:
          - name: etcd-operator
            image: quay.io/coreos/etcd-operator:v0.9.4
            command:
            - etcd-operator
            env:
            - name: MY_POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
    END
    ```

    Wait for the Etcd Operator Pod to start
    ```bash
    kubectl -n $NAMESPACE get pod -lapp=etcd-operator
    ```

1. Create the EtcdCluster resource

   ```yaml
   $ kubectl -n $NAMESPACE create -f - <<END
   apiVersion: "etcd.database.coreos.com/v1beta2"
   kind: "EtcdCluster"
   metadata:
     name: "storageos-etcd"
   spec:
     size: 3
     version: "3.4.7"
     pod:
       etcdEnv:
       - name: ETCD_QUOTA_BACKEND_BYTES
         value: "2147483648"  # 2 GB
       - name: ETCD_AUTO_COMPACTION_RETENTION
         value: "1000" # Keep 1000 revisions (default)
       - name: ETCD_AUTO_COMPACTION_MODE
         value: "revision" # Set the revision mode
       resources:
         requests:
           cpu: 200m
           memory: 300Mi
       securityContext:
         runAsNonRoot: true
         runAsUser: 9000
         fsGroup: 9000
       tolerations:
       - operator: "Exists"
       affinity:
         podAntiAffinity:
           preferredDuringSchedulingIgnoredDuringExecution:
           - weight: 100
             podAffinityTerm:
               labelSelector:
                 matchExpressions:
                 - key: etcd_cluster
                   operator: In
                   values:
                   - storageos-etcd
               topologyKey: kubernetes.io/hostname
   END
   ```

### Installation Verification

```bash
$ kubectl -n storageos-etcd get pod,svc
NAME                                 READY   STATUS    RESTARTS   AGE
pod/etcd-operator-55978c4587-8kx7b   1/1     Running   0          2h
pod/storageos-etcd-qm9tmrpnlm        1/1     Running   0          2h
pod/storageos-etcd-rzhjdz74hp        1/1     Running   0          2h
pod/storageos-etcd-wvvv2d9g98        1/1     Running   0          2h

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP PORT(S)             AGE
service/storageos-etcd          ClusterIP   None             <none>      2379/TCP,2380/TCP   22h
service/storageos-etcd-client   ClusterIP   172.30.132.255   <none>      2379/TCP            22h
```

> 💡 The URL from the Service `storageos-etcd-client.storageos-etcd.svc:2379`
> will be used later in the Ondat Cluster CustomResource the
> `kvBackend.address`.

## Known etcd-operator issues

Etcd is a distributed key-value store database focused on strong consistency.
That means that etcd nodes perform operations across the cluster to ensure
quorum. If quorum is lost, etcd nodes stop and etcd marks its contents as
read-only. This is because it cannot guarantee that new data will be valid.
Quorum is fundamental for etcd operations. When running etcd using the CoreOS
Operator, it is important to consider that a loss of quorum could arise from
etcd pods being evicted from nodes.

Operations such as Kubernetes Upgrades with rolling node pools could cause a
total failure of the etcd cluster as nodes are discarded in favor of new ones.

A 3 etcd node cluster can survive losing one node and recover, a 5 node
cluster can survive the loss of two nodes. Loss of further nodes will result in quorum being lost.

__The etcd-operator doesn't support a full stop of the cluster. Stopping the
etcd cluster causes the loss of all the etcd keystore and make Ondat
unable to perform metadata changes.__


## Production - Etcd on External Virtual Machines

For production installations, Ondat strongly recommends running etcd
outside of Kubernetes on a minimum of 3 dedicated virtual machines. This
topology offers strong guarantees of resilience and uptime. We recommend this
architecture in all environments, including those where Kubernetes is being
deployed as a managed service.

Ondat doesn't require a high performance etcd cluster, as the throughput
of metadata to the cluster is low. However, we recommend a careful assessment
of IOPS capacity [best practices](/docs/operations/etcd/_index#iops-requirements) to ensure that etcd
operates normally.

Depending on the level of redundancy you feel comfortable with you can install
etcd on the Kubernetes Master nodes. __Take extreme care to avoid collisions
of the Ondat etcd installation with the Kubernetes etcd when using the
Kubernetes Master nodes. Precautions such as changing the default
configuration for the client and peer ports, and ensuring the etcd data
directory is modified. The ansible playbook below will default the etcd
installation directory to `/var/lib/storageos-etcd`.__

You can choose between two installation options.
- [Manual Installation](#installation---manual)
- [Ansible Installation](#installation---ansible)


### Installation - Manual

This section documents the steps required for manual installation of etcd
using standard package management commands and systemd manifests.

> ⚠️ **Repeat the following steps on all the nodes that will run etcd as a
> systemd service.**

1. Configure Etcd version and ports

    ```bash
    export ETCD_VERSION="3.4.9"
    export CLIENT_PORT="2379"
    export PEERS_PORT="2380"
    ```
    > ⚠️ __If targeting Kubernetes Master nodes, you must change
    > `CLIENT_PORT`, `PEERS_PORT`__

1. Download Etcd from CoreOS official site

    ```bash
    curl -L https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    mkdir -p /tmp/etcd-v${ETCD_VERSION}-linux-amd64
    tar -xzvf /tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -C /tmp/etcd-v${ETCD_VERSION}-linux-amd64 --strip-components=1
    rm /tmp/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
    ```

1. Install Etcd binaries

    ```bash
    cd /tmp/etcd-v${ETCD_VERSION}-linux-amd64
    mv etcd /usr/local/sbin/etcd3
    mv etcdctl /usr/local/sbin/etcdctl
    chmod 0755 /usr/local/sbin/etcd3 /usr/local/sbin/etcdctl
    ```

1. Set up persistent Etcd data directory

    ```bash
    mkdir /var/lib/storageos-etcd
    ```

1. Create the systemd environment file

    On all nodes that will run etcd create a systemd environemnt file
    `/etc/etcd.conf` which has the IPs of all the nodes. The `NODE_IP` will
    need to change to correspond to the node IP where the environment file
    resides. `NODE1_IP`, `NODE2_IP` and `NODE3_IP` will remain the same across
    all three files.

    ```bash
    $ cat <<END > /etc/etcd.conf
    # NODE_IP is the IP of the node where this file resides.
    NODE_IP=10.64.10.228
    # Node 1 IP
    NODE1_IP=10.64.10.228
    # Node 2 IP
    NODE2_IP=10.64.14.233
    # Node 3 IP  
    NODE3_IP=10.64.12.111
    CLIENT_PORT=${CLIENT_PORT}
    PEERS_PORT=${PEERS_PORT}
    END

    # Verify that variables are expanded in the file
    $ cat /etc/etcd.conf

    ```

1. Create the systemd unit file for etcd3 service

    Create a systemd unit file `/etc/systemd/system/etcd3.service` with the
    following information:

    ```bash
    [Unit]
    Description=etcd3
    Documentation=https://github.com/coreos/etcd
    Conflicts=etcd2.service

    [Service]
    Type=notify
    Restart=always
    RestartSec=5s
    LimitNOFILE=40000
    TimeoutStartSec=0
    EnvironmentFile=/etc/etcd.conf

    ExecStart=/usr/local/sbin/etcd3 --name etcd-${NODE_IP} \
        --heartbeat-interval 500 \
        --election-timeout 5000 \
        --max-snapshots 10 \
        --max-wals 10 \
        --data-dir /var/lib/storageos-etcd \
        --quota-backend-bytes 8589934592 \
        --snapshot-count 100000 \
        --auto-compaction-retention 20000 \
        --auto-compaction-mode revision \
        --initial-cluster-state new \
        --initial-cluster-token etcd-token \
        --listen-client-urls http://${NODE_IP}:${CLIENT_PORT},http://127.0.0.1:${CLIENT_PORT} \
        --advertise-client-urls http://${NODE_IP}:${CLIENT_PORT} \
        --listen-peer-urls http://${NODE_IP}:${PEERS_PORT} \
        --initial-advertise-peer-urls http://${NODE_IP}:${PEERS_PORT} \
        --initial-cluster etcd-${NODE1_IP}=http://${NODE1_IP}:${PEERS_PORT},etcd-${NODE2_IP}=http://${NODE2_IP}:${PEERS_PORT},etcd-${NODE3_IP}=http://${NODE3_IP}:${PEERS_PORT}


    [Install]
    WantedBy=multi-user.target
    ```

    > 💡 `$NODE_IP` is the IP address of the machine you are installing etcd on.`

    > ⚠️ Note that setting the advertise-client-urls incorrectly will cause any
    > client connection to fail. Ondat will fail to communicate to Etcd.

    > ⚠️ If enabling TLS, it is recomended to generate your own CA certificate
    > and key. You will need to distribute the keys and certificates for the
    > client auth on all etcd nodes. Moreover, the `ExecStart` value should
    > look as below:

    ```bash
        ExecStart=/usr/local/sbin/etcd3 --name etcd-${NODE_IP} \
        --heartbeat-interval 500 \
        --election-timeout 5000 \
        --max-snapshots 10 \
        --max-wals 10 \
        --data-dir /var/lib/storageos-etcd \
        --quota-backend-bytes 8589934592 \
        --snapshot-count 100000 \
        --auto-compaction-retention 20000 \
        --auto-compaction-mode revision \
        --peer-auto-tls \
        --client-cert-auth --trusted-ca-file=/path/to/client-cert.pem \
        --cert-file=/path/to/ca.pem \
        --key-file=/path/to/client-key.pem \
        --initial-cluster-state new \
        --initial-cluster-token etcd-token \
        --listen-client-urls https://${NODE_IP}:${CLIENT_PORT} \
        --advertise-client-urls https://${NODE_IP}:${CLIENT_PORT} \
        --listen-peer-urls https://${NODE_IP}:${PEERS_PORT} \
        --initial-advertise-peer-urls https://${NODE_IP}:${PEERS_PORT} \
        --initial-cluster etcd-${NODE1_IP}=https://${NODE1_IP}:${PEERS_PORT},etcd-${NODE2_IP}=https://${NODE2_IP}:${PEERS_PORT},etcd-${NODE3_IP}=https://${NODE3_IP}:${PEERS_PORT}
    ```

1. Reload and start the etc3 systemd service

    ```bash
    $ systemctl daemon-reload
    $ systemctl enable etcd3.service
    $ systemctl start  etcd3.service
    ```

1. Installation Verification

    > 💡 The `etcdctl` binary is installed at `/usr/local/bin` on the nodes.

    ```bash
    $ ssh $NODE # Any node running the new etcd
    $ ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:${CLIENT_PORT} member list # $NODE_IP - the IP of the node
    66946cff1224bb5, started, etcd-b94bqkb9rf,  http://172.28.0.1:2380, http://172.28.0.1:2379
    17e7256953f9319b, started, etcd-gjr25s4sdr, http://172.28.0.2:2380, http://172.28.0.2:2379
    8b698843a4658823, started, etcd-rqdf9thx5p, http://172.28.0.3:2380, http://172.28.0.3:2379
    ```

    > 💡 Read the [etcd operations](/docs/operations/etcd/_index)
    > page for our etcd recommendations.

### Installation - Ansible

For a repeatable and automated installation, use of a configuration management
tool such as ansible is recommended. Ondat provides an ansible playbook to
help you deploy etcd on standalone virtual machines.

1. Clone Ondat deployment repository
    ```bash
    git clone https://github.com/storageos/deploy.git
    cd k8s/deploy-storageos/etcd-helpers/etcd-ansible-systemd
    ```
1. Edit the inventory file
    > 💡 The inventory file targets the nodes that will run etcd. The file
    > `hosts` is an example of such an inventory file.


    ```bash
    $ cat hosts
    [nodes]
    centos-1 ip="10.64.10.228" fqdn="ip-10-64-10-228.eu-west-2.compute.internal"
    centos-2 ip="10.64.14.233" fqdn="ip-10-64-14-233.eu-west-2.compute.internal"
    centos-3 ip="10.64.12.111" fqdn="ip-10-64-12-111.eu-west-2.compute.internal"

    # Edit the inventory file
    $ vi hosts # Or your own inventory file
    ```

    > ⚠️ The ip or fqdn are used to expose the advertise-client-urls of Etcd.
    > Failing to provide valid ip/fqdn will cause any client connection to
    > fail. Ondat will fail to communicate to Etcd.

1. Edit the etcd configuration
    > ⚠️  __If targeting Kubernetes Master nodes, you must change
    > `etcd_port_client`, `etcd_port_peers`__

    ```bash
    $ cat group_vars/all
    etcd_version: "3.4.9"
    etcd_port_client: "2379"
    etcd_port_peers: "2380"
    etcd_quota_bytes: 8589934592  # 8 GB
    etcd_auto_compaction_mode: "revision"
    etcd_auto_compaction_retention: "1000"
    members: "{{ groups['nodes'] }}"
    installation_dir: "/var/lib/storageos-etcd"
    advertise_format: 'fqdn' # fqdn || ip
    backup_file: "/tmp/backup.db"

    tls:
      enabled: false
      ca_common_name: "eu-west-2.compute.internal"
      etcd_common_name: "*.eu-west-2.compute.internal"
      cert_dir: "/etc/etcdtls"
      ca_cert_file: "etcd-ca.pem"
      etcd_server_cert_file: "server.pem"
      etcd_server_key_file: "server-key.pem"
      etcd_client_cert_file: "etcd-client.crt"
      etcd_client_key_file: "etcd-client.key"

    $ vi group_vars/all
    ```

    > 💡 Choose between using IP addressing or FQDN in the `advertise_format`
    > parameter. It allows you to decide how Etcd advertises its address to
    > clients. This is particularly relevant when using TLS.

    > 💡 If enabling TLS, it is recomended to generate your own CA certificate
    > and key. You can do it by generating the CA from the machine running
    > Ansible by: `ansible-playbook create_ca.yaml`.

1. Install
    ```bash
    ansible-playbook -i hosts install.yaml
    ```

1. Installation Verification
    > 💡 The playbook installs the `etcdctl` binary on the nodes, at
    > `/usr/local/bin`.

    ```bash
    $ ssh $NODE # Any node running the new etcd
    $ ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 member list
    66946cff1224bb5, started, etcd-b94bqkb9rf,  http://172.28.0.1:2380, http://172.28.0.1:2379
    17e7256953f9319b, started, etcd-gjr25s4sdr, http://172.28.0.2:2380, http://172.28.0.2:2379
    8b698843a4658823, started, etcd-rqdf9thx5p, http://172.28.0.3:2380, http://172.28.0.3:2379
    ```

## Benefits of Running External to Kubernetes

Etcd is a distributed key-value store database focused on strong consistency.
That means that etcd nodes perform operations across the cluster to ensure
quorum. In the case that quorum is lost, an etcd node stops and marks its
contents as read-only. Another peer might have a newer version that has not
been committed to the database. Quorum is fundamental for etcd operations.

In a Kubernetes environment, applications are scheduled across and in some
scenarios such as "DiskPressure" they may need to be evicted from a node, and
be scheduled onto a different node. With an application such as etcd, the
scenario described can result in quorum being lost, making the cluster unable
to recover automatically. Usually a 3 node etcd cluster can survive losing one
node and recover. However, losing a second node at the same time or even
having a network partition between them will result in quorum lost.

## Bind Etcd IPs to Kubernetes Service

Kubernetes external services use a DNS name to reference external endpoints,
making them easy to reference from inside the cluster.  You can use the
example from the [helper github repository](https://github.com/storageos/deploy/tree/master/k8s/deploy-storageos/etcd-helpers/etcd-external-svc)
to deploy the external Service. Using an external service can make monitoring
of etcd from Prometheus easier.

## Using Etcd with Ondat

During installation of Ondat the `kvBackend.address` parameter of the
Ondat operator is used to specify the address of the etcd cluster. See the
[Ondat cluster operator configuration](/docs/reference/cluster-operator/examples#installing-with-an-external-etcd) examples for more information.
