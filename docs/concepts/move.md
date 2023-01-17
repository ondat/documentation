---
title: "Move"
linkTitle: "Move"
weight: 1
---

## Moving Ondat volume instances

A volume instance (replica or primary) can be moved freely between nodes, this can be extremely useful in very specific scenarios, and it's available through a new command in the command-line tool.

It allows to manually re-balance a cluster, reduce load on over-loaded nodes, etc.

## Example of use

Here's an example of how the CLI cmd works:

```bash
storageos update volume move my-volume-id source-node-id destination-node-id --namespace my-namespace-name
```

## Moving to where an instance already exists

When trying to move an Ondat volume instance into a node with another instance, the only scenario where this is valid is when the source node coincides with the primary and the destination node with the replica, in which case we take an approach of moving the "roles" as opposed to the data itself thus attempt to promote the replica on destination node to be the new primary instance of the Ondat volume.

⚠️ Nothing will happen when trying to move a replica instance of an Ondat volume to another replica instance as there's no functional distinction between the two.

## Safety first

The process is safe to use and only ever removes data when a new instance of it has been synced within the new node.
