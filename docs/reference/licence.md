---
linkTitle: Licence
description: >
  A cluster requires a licence to be issued within the first 24 hours.
---

# Licence

A newly installed Ondat cluster does not include a licence. A cluster can
run unlicensed for 24 hours. After that, new operations such as volume
provisioning or adding nodes are not permitted. Normal functioning of the
cluster can be unlocked by applying a Free Personal licence.

To learn how to apply a licence to your cluster, check the [operations
licensing](/docs/operations/licensing) page.

## Free Personal licence

The personal licence only requires the user to register and issue a
licence through Ondat.

The personal licence is free and grants a licence for a 3 node Ondat
cluster with 1TiB of provisioned capacity. It is designed to enable basic cloud
native workflows in Kubernetes that require the persistence of stateful
application data. Dynamic provisioning, distributed access to data and high
availability of volumes through synchronous replication and automatic failover
are some of the features that are available under the personal licence.

## Commercial licences

For information on our commercial offerings, including support, please contact
sales@storageos.com.

## Note about capacity limits

Some Ondat licences have limits on capacity. Ondat allows provisioning
volumes until the limit of the licence is reached. Only the size of the volume
requested by the Persistent Volume Claim counts for the licence limit,
regardless whether of whether the volume has replication enabled.

Once the licence limit is reached, new volumes are not able to provision unless
provisioned capacity is released, i.e deleting volumes. That behaviour is not
tied to the capacity of the backend disks on your nodes.

