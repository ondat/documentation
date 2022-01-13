---
linkTitle: Etcd
---

# Etcd

Check the [etcd prerequisites page](/docs/prerequisites/etcd)
for a step by step installation of etcd.

## Best practices

Ondat uses etcd as a service, whether it is deployed following the 
[step by step](/docs/prerequisites/etcd) instructions or as a custom
installation. It is expected that the user maintains the availability and
integrity of the etcd cluster.

It is highly recommended to keep the cluster backed up and ensure high
availability of its data.

### Network low latency

It is important to keep the latency between Ondat nodes and the etcd
replicas low. Deploying an etcd cluster in a different data center or region
can make Ondat detect etcd nodes as unavailable due to latency. 10ms
latency between Ondat and etcd would be the maximum threshold for proper
functioning of the system.

### Disk low latency

Etcd is very sensitive to disk latency. Because of that, it is recommended to
run etcd away from other IO-intensive workloads. Operations such as backups,
builds or application bundling cause a heavy usage of disks. If such
operations run alongside the etcd nodes, they will cause etcd to become
unstable and suffer downtime. It is best to run etcd nodes isolated from other
IO workloads.

### IOPS requirements

As a general rule, for etcd to operate normally on production clusters, we
recommend using the size of machine offered by your cloud provider that
guarantees a minimum of 500 IOPS. For example, 750 baseline IOPS are
guaranteed on a 250GB AWS gp2 EBS instance at time of writing, and block
instances on other cloud providers will also specify baseline IOPS figures.

Cloud providers usually provide "bursts" of IOPS - temporarily higher rates,
limited by credits - with larger volumes providing higher burst capacity. If
you are relying on burst capacity for etcd, which requires sustained high
performance, careful assessment is necessary to ensure sufficient capacity.

The rate of etcd operations is affected by the number of nodes, volumes and
replicas in the cluster, therefore the figure of 500 is provided as a
guideline only. A development cluster with 5 nodes will not have the same etcd
traffic as a production cluster with 100 nodes. Adding [monitoring](/docs/operations/etcd/_index#monitoring) to etcd will help to
characterise the traffic, and therefore to assess the individual requirements
of a cluster and adjust its resources accordingly.

### Etcd advertise urls

The etcd startup parameters `advertise-client-urls` and
`initial-advertise-peer-urls` specify the addresses etcd clients or other etcd
members should use to contact the etcd server. The advertised addresses must
be reachable from the remote machines - i.e. where Ondat is running - so
it can connect successfully. Do not advertise addresses like `localhost` or
`0.0.0.0` for a production setup since these addresses are unreachable from
remote machines.

### Monitoring

It is highly recommended to add monitoring to the etcd cluster. Etcd serves
Prometheus metrics on the client port `http://etcd-url:2379/metrics`.

You can use Ondat developed Grafana Dashboards for etcd. When using etcd
for production, you can use the
[etcd-cluster-as-service](https://grafana.com/grafana/dashboards/10322), while
the [etcd-cluster-as-pod](https://grafana.com/grafana/dashboards/10323) can be
used when using etcd from the operator.

### Defragmentation

Etcd uses revisions to store multiple versions of keys. Compaction removes all
key revision prior to a certain revision from etcd. Typically the etcd
configuration enables the automatic compaction of keys to prevent performance
degradation and limit the storage required. Compaction of revisions can create
fragmentation that means space on disk is available for use by etcd but is
unavailable for use by the file system. In order to reclaim this space, etcd
can be defragmented.

Reclaiming space is important because when the etcd database file grows over
the "DB_BACKEND_BYTES" parameter, the cluster triggers an alarm and sets
itself read only and only allows reads and deletes. To avoid hitting the db
backend bytes limit, compaction and defragmentation are required. How often
defragmentation is required depends on the churn of key revisions in etcd.

The Grafana Dashboards mentioned above indicate when nodes require
defragmentation. Be aware that defragmentation is a blocking operation that is
performed per node, hence the etcd node will be locked for the duration of the
defragmentation. Defragmentation usually takes a few milliseconds to complete.

You can also set cronjobs that execute the following defragmentation script.
It will run a defrag when the DB is at 80% full. A defragmentation operation
has to be executed per etcd node and __it is a blocking operation__. It is
recommended to __not execute the defragmentation on all etcd members at the
same time__. If using a cronjob, set them up for different times.

```bash curl -sSLo defrag-etcd.sh
https://raw.githubusercontent.com/storageos/deploy/master/k8s/deploy-storageos/etcd-helpers/etcd-ansible-systemd/roles/install_etcd/templates/defrag-etcd.sh.j2
chmod +x defrag-etcd.sh
```

## Known CoreOS Etcd Operator issues

This topology is only recommended for deployments where isolated nodes cannot
be used.

Etcd is a distributed key-value store database focused on strong consistency.
That means that etcd nodes perform operations across the cluster to ensure
quorum. If quorum is lost, etcd nodes stop and etcd marks its contents as
read-only. This is because it cannot guarantee that new data will be valid.
Quorum is fundamental for etcd operations. When running etcd in pods it is
therefore important to consider that a loss of quorum could arise from etcd
pods being evicted from nodes.

Operations such as Kubernetes Upgrades with rolling node pools could cause a
total failure of the etcd cluster as nodes are discarded in favor of new ones.

A 3 etcd node cluster can survive losing one node and recover, a 5 node
cluster can survive the loss of two nodes. Loss of further nodes will result
in quorum being lost.

__The etcd-operator doesn't support a full stop of the cluster. Stopping the
etcd cluster causes the loss of all the etcd keystore and make Ondat
unable to perform metadata changes.__

The official etcd-operator repository also has a backup deployment operator
that can help backup etcd data. __A restore of the etcd keyspace from a backup
might cause issues__ due to the disparity between the cluster state and its
metadata in a different point in time. If you need to restore from a backup
after a failure of etcd, contact the Ondat support team.