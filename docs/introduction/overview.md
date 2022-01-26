---
title: "Ondat Overview"
linkTitle: Ondat Overview
weight: 10
description: >
    Ondat V2 is built from the knowledge and experience of running
    stateful production workloads in the fast changing container world.
---

Over the past several months, we've been hard at work on Ondat V2, which
contains some significant enhancements over our v1 product. We've built V2
based on our observations of trends in the industry, as well as our own
experience.

Many of our customers want to run big clusters - in the tens or hundreds of
nodes. In these sorts of big environments, the challenges multiply. Not only do
we need to scale well, but we also need to be more failure tolerant. Bigger
environments typically suffer higher failure rates (more nodes = greater chance
of something failing), but are also subject to all sorts of transient
conditions such as network partitions.

The second trend we've seen become increasingly common is the desire to run
multiple clusters, and consume storage between them in some way - sometimes to
implement novel topologies such as a centralised storage cluster with
satellites consuming the storage, and sometimes to replicate data between those
clusters for HA or DR purposes.

We've built V2 with these architectures and design patterns in mind. Not only
does it scale well, but it contains the foundations we need to implement a rich
set of multi-cluster functionality.

## 🚀 Upgraded Control Plane

At the heart of the V2 release is an upgraded control plane. We've changed a
lot here. Firstly, our usage of etcd is vastly improved. We've learnt a lot
about the subtleties of distributed consensus in the last year, particularly in
noisy or unpredictable environments. Not only is Ondat V2 much lighter on
your etcd cluster, but it's a lot more tolerant of transient failure conditions
that are often found in cloud environments, or clusters under heavy load.

We spent some time describing and testing our internal state machine using the
[TLA+](https://en.wikipedia.org/wiki/TLA%2B) formal verification language. This
allows us to have a much higher degree of confidence that our algorithms will
behave correctly, particularly under hard-to-test edge cases and failure
conditions.

Additionally, we've changed the way volumes behave with respect to centralised
scheduling. Each volume group (consisting of a master and 0 or more replicas)
now behaves as a strongly consistent unit allowing it to take action
independent of the activities of the rest of the cluster. Other state can be
distributed around the cluster using eventually consistent mechanisms. This
approach inherently scales better and allows Ondat V2 to effectively manage
many more nodes and volumes than before.

We've implemented TLS on all endpoints. Not only does this give you encrypted
traffic between nodes in your storage cluster, it also protects all endpoints
with strong, public key based authentication. Today's IT environments can't
rely on firewalls to keep bad actors out - they must implement security at all
layers within the stack - defense in depth. While we recognise that this brings
a welcome relief to many security conscious administrators, we also know that
managing certificate authorities (CAs) can be an unwelcome source of
complexity. For this reason, Ondat V2 implements an internal CA by default,
to manage this complexity for you. If you'd prefer to integrate your own CA, we
support that too - it's up to you.

Finally - our logging has undergone a complete transformation in this edition. We
know that systems engineers and operators don't just value headline features,
but that observability and diagnostics are equally important. All logs are now
decorated with rich context to help you understand what is happening within
your cluster, and we'll output in json by default, for easy ingestion into log
aggregators such as Elasticsearch.

## 🚀 Upgraded Data Plane

Not to be outdone, our data plane contains some significant improvements.

Firstly, we've completely re-written our sync algorithm (see [Delta Sync](/docs/concepts/volumes), used when seeding or catching up replicas
that have been offline or partitioned. Our new algorithm uses a [Hash
List](https://en.wikipedia.org/wiki/Hash_list) to sync only changed sections of
a volume (similar in some ways to what rsync does). Ondat maintains these
hashes during normal operation, meaning that when resyncing a failed replica,
for example after a node reboot, we can very quickly and efficiently catch this
replica up, rather than needing to promote and build a new one from scratch.
This improves resiliency within your cluster, and prevents using excessive
network bandwidth during failover conditions - at a time when it might be
needed the most.

Secondly, a new threading model, with dynamic pool sizing, means that Ondat
is faster, a lot faster. In our tests we observed improvements across the
board, with improvements in throughput of up to 135% for some scenarios.
