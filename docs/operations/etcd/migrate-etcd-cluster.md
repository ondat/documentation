---
linkTitle: Etcd node migration
---

# Etcd node migration

This procedure explains how to add a new etcd member for your Ondat etcd
cluster while removing one of the current members. This is useful when the
nodes hosting etcd must be recycled.

> **It is assumed** that the Ondat etcd cluster is installed following the
> [production etcd installation](/docs/prerequisites/etcd#production)
> page, where etcd nodes are installed on their own machines.

> **It is also assumed** that etcd members are referenced from Kubernetes using a External
> Service. Example available in the [etcd external
> Service](https://github.com/storageos/deploy/tree/master/k8s/deploy-storageos/etcd-helpers/etcd-external-svc)
> example. This service should be referred to in the `spec.kvbackend.address`
> section of your Ondat CustomResource. If that Service is not used, **a full
> restart** of the Ondat cluster will be required. The Ondat
> CustomResource would need to be removed, and amended to reflect the new etcd
> urls created.

## Preparation

Prepare the installation of etcd on a new node, __making sure that etcd is not
starting__ on that new node.

The steps for preparing an etcd node can be found in the [etcd prerequisites](/docs/prerequisites/etcd#production)
page.

1. Back up etcd

    ```
    $ export ETCDCTL_API=3

    $ # Set all your endpoints
    $ export endpoints="192.168.174.117:2379,192.168.195.168:2379,192.168.174.117:2379"

    $ etcdctl --endpoints $endpoints snapshot save /var/tmp/etcd-snapshot.db
    ```

1. Verify etcd health

    ```
    $ export ETCDCTL_API=3

    $ # Set all your endpoints
    $ export endpoints="192.168.174.117:2379,192.168.195.168:2379,192.168.174.117:2379"
    $ etcdctl member list --endpoints $endpoints -wtable
    +------------------+---------+-----------------------+------------------------------+-----------------------------+------------+
    |        ID        | STATUS  |         NAME          |         PEER ADDRS           |        CLIENT ADDRS         | IS LEARNER |
    +------------------+---------+-----------------------+------------------------------+-----------------------------+------------+
    | 7817aa073b059aab | started |  etcd-192.168.195.168 |  http://192.168.195.168:2380 | http://192.168.195.168:2379 |      false |
    | e22cdd20a03e5e73 | started |  etcd-192.168.202.40  |  http://192.168.202.40:2380  | http://192.168.202.40:2379  |      false |
    | e5d0f0e242014d3d | started |  etcd-192.168.174.117 |  http://192.168.174.117:2380 | http://192.168.174.117:2379 |      false |
    +------------------+---------+-----------------------+------------------------------+-----------------------------+------------+

    $ etcdctl endpoint health --endpoints $endpoints -wtable
    +---------------------+--------+------------+-------+
    |      ENDPOINT       | HEALTH |    TOOK    | ERROR |
    +---------------------+--------+------------+-------+
    |192.168.174.117:2379 |   true | 5.048177ms |       |
    |192.168.195.168:2379 |   true | 5.926681ms |       |
    |192.168.202.40:2379  |   true | 5.526928ms |       |
    +---------------------+--------+------------+-------+

    $ etcdctl endpoint status --endpoints $endpoints -wtable
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |      ENDPOINT       |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |192.168.174.117:2379 | e5d0f0e242014d3d |   3.4.9 |  311 kB |     false |      false |         2 |       4281 |               4281 |        |
    |192.168.195.168:2379 | 7817aa073b059aab |   3.4.9 |  315 kB |     false |      false |         2 |       4281 |               4281 |        |
    |192.168.202.40:2379  | e22cdd20a03e5e73 |   3.4.9 |  352 kB |      true |      false |         2 |       4281 |              4281  |        |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```

## Migration

> In the following procedure NODE4 is a new member to add to the cluster, while
> NODE1 ought to be removed.

1. Amend etcd configuration to reference the new node (NODE4)

    > Make the following change on all running etcd members and NODE4

    ```
    $ # NODE4_IP is the NEW_NODE_ADDRESS
    $ echo "NODE4_IP=192.168.152.142" >> /etc/etcd.conf

    $ # Check the contents of /etc/etcd.conf
    $ cat /etc/etcd.conf
    CLIENT_PORT=2379
    PEERS_PORT=2380

    # NODE_IP is the IP of the node where this file resides.
    NODE_IP=192.168.202.40

    NODE1_IP=192.168.195.168
    NODE2_IP=192.168.202.40
    NODE3_IP=192.168.174.117
    NODE4_IP=192.168.152.142
   ```

1. Amend SystemD service file on the new etcd node (NODE4)

    > The SystemD service file is expected in `/etc/systemd/system/etcd3.service`

    Change the `--initial-cluster-state` to `existing` and add the reference to
    NODE4 in the `--initial-cluster` variable.

    ```
    vi /etc/systemd/system/etcd3.service
    ```

    The resulting changes would appear as follows:
    ```
    ...

    ExecStart=/usr/local/sbin/etcd3 --name etcd-${NODE_IP} \
       ...
       --initial-cluster-state existing \
       ...
       --initial-cluster \
            etcd-${NODE1_IP}=http://${NODE1_IP}:${PEERS_PORT},\
            etcd-${NODE2_IP}=http://${NODE2_IP}:${PEERS_PORT},\
            etcd-${NODE3_IP}=http://${NODE3_IP}:${PEERS_PORT},\
            etcd-${NODE4_IP}=http://${NODE4_IP}:${PEERS_PORT}
    ...

    ```

    > Note the reference to NODE4 at the end of the `--initial-cluster`
    > variable

    __Make sure etcd is not started on the new member NODE4__

1. Add etcd member as a `learner`

   ```bash
   # Set environment variable for the the new etcd member (NODE4)
   $ NODE4_IP=192.168.152.142

   $ ETCD_NEW_MEMBER="etcd-${NODE4_IP}"
   $ ETCD_NEW_MEMBER_PEER="http://$NODE4_IP:2380"

   # Add the new member to the cluster
   $ export ETCDCTL_API=3

   $ etcdctl member add \
        --learner $ETCD_NEW_MEMBER \
        --peer-urls="$ETCD_NEW_MEMBER_PEER"

    Member 52e5c9ac117b3df2 added to cluster b4f4ed717ea44b8d

    ETCD_NAME="etcd-192.168.152.142"
    ETCD_INITIAL_CLUSTER="etcd-192.168.152.142=http://192.168.152.142:2380,etcd-192.168.195.168=http://192.168.195.168:2380,etcd-192.168.202.40=http://192.168.202.40:2380,etcd-192.168.174.117=http://192.168.174.117:2380"
    ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.152.142:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"
   ```


1. Check the etcd members
    ```
    $ export endpoints="192.168.174.117:2379,192.168.195.168:2379,192.168.174.117:2379"

    $ etcdctl member list --endpoints $endpoints -wtable
    +------------------+-----------+----------------------+-----------------------------+-----------------------------+------------+
    |        ID        |  STATUS   |         NAME         |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
    +------------------+-----------+----------------------+-----------------------------+-----------------------------+------------+
    | 52e5c9ac117b3df2 | unstarted |                      | http://192.168.152.142:2380 |                             |       true |
    | 7817aa073b059aab |   started | etcd-192.168.195.168 | http://192.168.195.168:2380 | http://192.168.195.168:2379 |      false |
    | e22cdd20a03e5e73 |   started | etcd-192.168.202.40  | http://192.168.202.40:2380  | http://192.168.202.40:2379  |      false |
    | e5d0f0e242014d3d |   started | etcd-192.168.174.117 | http://192.168.174.117:2380 | http://192.168.174.117:2379 |      false |
    +------------------+-----------+----------------------+-----------------------------+-----------------------------+------------+
    ```

    > Note that the learner is not started yet


1. Start etcd on the new node (NODE4)

    > Make sure that `/etc/systemd/system/etcd.service` only have __currently
    > active__ nodes specified in the `--initial-cluster` flag.

   ```bash
   # On the new node (NODE4)

   systemctl daemon-reload
   systemctl enable etcd3.service
   systemctl start etcd3.service
   ```

1. Check the etcd members

    ```
    $ export endpoints="192.168.174.117:2379,192.168.195.168:2379,192.168.174.117:2379"

    $ etcdctl member list --endpoints $endpoints -wtable
    +------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
    |        ID        | STATUS  |         NAME         |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
    +------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
    | 52e5c9ac117b3df2 | started | etcd-192.168.152.142 | http://192.168.152.142:2380 | http://192.168.152.142:2379 |       true |
    | 7817aa073b059aab | started | etcd-192.168.195.168 | http://192.168.195.168:2380 | http://192.168.195.168:2379 |      false |
    | e22cdd20a03e5e73 | started | etcd-192.168.202.40  | http://192.168.202.40:2380  | http://192.168.202.40:2379  |      false |
    | e5d0f0e242014d3d | started | etcd-192.168.174.117 | http://192.168.174.117:2380 | http://192.168.174.117:2379 |      false |
    +------------------+---------+----------------------+-----------------------------+-----------------------------+------------+

    ```

    > Note that the learner is started

1. Check that the new learner has the same revision applied as the current
   members

    ```
    $ export ETCDCTL_API=3
    # Added NODE4 in the endpoints variable
    $ export endpoints="192.168.174.117:2379,192.168.195.168:2379,192.168.174.117:2379,192.168.152.142:2379"

    etcdctl endpoint status --endpoints $endpoints -wtable
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |      ENDPOINT       |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 192.168.174.117:2379| e5d0f0e242014d3d |   3.4.9 |  352 kB |     false |      false |         2 |      24570 |              24570 |        |
    | 192.168.195.168:2379| 7817aa073b059aab |   3.4.9 |  352 kB |     false |      false |         2 |      24570 |              24570 |        |
    | 192.168.202.40:2379 | e22cdd20a03e5e73 |   3.4.9 |  352 kB |     true  |      false |         2 |      24570 |              24570 |        |
    | 192.168.152.142:2379| 52e5c9ac117b3df2 |   3.4.9 |  467 kB |     false |       true |         2 |      24570 |              24570 |        |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```

    > Wait until the cluster has the learner ready, by ensuring that the
    > RAFT TERM and RAFT INDEX of the learner node match the rest of the
    > cluster.


1. Remove the node that needs to be evicted (NODE1)

    > Before promoting the learner to a full member, it is best to remove the
    > node from the cluster that initially was selected to be decommissioned to
    > avoid breaking quorum while having 4 nodes being part of the cluster. For
    > more details, check the [official etcd
    > documentation](https://etcd.io/docs/v3.4/faq/#should-i-add-a-member-before-removing-an-unhealthy-member)
    > regarding this topic.

    ```
    $ export ETCDCTL_API=3

    $ # Select member of id of the node to remove (NODE1)
    $ NODE1_MEMBER_ID=e22cdd20a03e5e73

    $ etcdctl member remove $NODE1_MEMBER_ID
    Member e22cdd20a03e5e73 removed from cluster b4f4ed717ea44b8d
    ```


1. Promote the learner to a member

    ```
    $ export ETCDCTL_API=3

    $ # Select member of id of the node to remove (NODE1)
    $ NODE4_MEMBER_ID=52e5c9ac117b3df2

    $ etcdctl member promote $NODE4_MEMBER_ID
    Member 52e5c9ac117b3df2 promoted in cluster b4f4ed717ea44b8d
    ```

   > The promotion will fail if the learner is not in sync with the leader
   > member.

1. Check the etcd health

    ```
    $ export endpoints=192.168.174.117:2379,192.168.195.168:2379,192.168.152.142:2379

    $ etcdctl member list --endpoints $endpoints -wtable
    +------------------+---------+---------------------+----------------------------+----------------------------+------------+
    |        ID        | STATUS  |        NAME         |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
    +------------------+---------+---------------------+----------------------------+----------------------------+------------+
    | 52e5c9ac117b3df2 | started |etcd-192.168.152.142 |http://192.168.152.142:2380 |http://192.168.152.142:2379 |      false |
    | 7817aa073b059aab | started |etcd-192.168.195.168 |http://192.168.195.168:2380 |http://192.168.195.168:2379 |      false |
    | e5d0f0e242014d3d | started |etcd-192.168.174.117 |http://192.168.174.117:2380 |http://192.168.174.117:2379 |      false |
    +------------------+---------+---------------------+----------------------------+----------------------------+------------+

    $ etcdctl endpoint status --endpoints $endpoints -wtable
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |      ENDPOINT       |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |192.168.174.117:2379 | e5d0f0e242014d3d |   3.4.9 |  352 kB |     false |      false |         3 |      35939 |              35939 |        |
    |192.168.195.168:2379 | 7817aa073b059aab |   3.4.9 |  352 kB |      true |      false |         3 |      35939 |              35939 |        |
    |192.168.152.142:2379 | 52e5c9ac117b3df2 |   3.4.9 |  467 kB |     false |      false |         3 |      35939 |              35939 |        |
    +---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```

    > Note that NODE4 is now a full quorum member, while NODE1 is no longer
    > part of the cluster

1. Edit Endpoints referencing the Kubernetes Service

    > Remove the reference to NODE1 and add the IP for NODE4

   ```bash
   $ kubectl edit -n storageos-etcd endpoints/storageos-etcd
   ```

1. Make amendments in the SystemD configuration files removing any reference to
   NODE1

   > It is not required to restart the etcd service, but to keep the service
   > file up to date.
