---
title: "Etcd outside the cluster"
linkTitle: Etcd outside the cluster
weight: 600
---

This page documents the process for installing etcd outside the Kubernetes cluster.


In some circumstances it can make sense to run etcd outside of Kubernetes. One
of such circumstances is running an on-premises Kubernetes cluster and not
having access to reliable cloud disks (for storing etcd data).

For production installations running etcd outside the cluster, Ondat strongly
recommends running etcd on a minimum of 3 dedicated virtual machines. This
topology offers strong guarantees of resilience and uptime.

Ondat doesn't require a high performance etcd cluster, as the throughput of
metadata to the cluster is low. However, we recommend a careful assessment of
IOPS capacity [best practices](/docs/operations/etcd/) to ensure that etcd
operates normally.

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

    On all nodes that will run etcd create a systemd environment file
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
    systemctl daemon-reload
    systemctl enable etcd3.service
    systemctl start  etcd3.service
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

    > Read the [etcd operations](/docs/operations/etcd/)
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

## Bind Etcd IPs to Kubernetes Service

Kubernetes external services use a DNS name to reference external endpoints,
making them easy to reference from inside the cluster.  You can use the example
from the [helper GitHub
repository](https://github.com/storageos/deploy/tree/master/k8s/deploy-storageos/etcd-helpers/etcd-external-svc)
to deploy the external Service. Using an external service can make monitoring
of etcd from Prometheus easier.

## Using Etcd with Ondat

During installation of Ondat the `kvBackend.address` parameter in the
`storageoscluster` custom resource is used to specify the address of the etcd
cluster.
